//
//  IAPManager.swift
//  BabyDaily
//
//  内购管理类
//  负责处理应用内购买相关的所有逻辑，包括产品获取、购买流程、交易验证等
//

import Foundation
import StoreKit
import Combine

/// 内购产品ID常量
struct IAPProductID {
    /// 高级会员（永久）
    static let premiumMembership = "cn.iizhi.babydaily.lifetime"
    static let monthlyMembership = "cn.iizhi.babydaily.monthly_subscribe"
}

/// 购买状态枚举
enum PurchaseStatus {
    case idle           // 空闲状态
    case loading        // 加载中
    case purchasing     // 购买中
    case success        // 购买成功
    case failed(String) // 购买失败（包含错误信息）
    case restored       // 恢复购买成功
}

extension PurchaseStatus: Equatable {
    static func == (lhs: PurchaseStatus, rhs: PurchaseStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.purchasing, .purchasing), (.success, .success), (.restored, .restored):
            return true
        case (.failed(let l), .failed(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// 内购管理器
@MainActor
class IAPManager: NSObject, ObservableObject {
    // MARK: - 单例模式
    static let shared = IAPManager()
    
    // MARK: - Published Properties
    /// 产品列表
    @Published var products: [Product] = []
    
    /// 购买状态
    @Published var purchaseStatus: PurchaseStatus = .idle
    
    /// 是否已购买高级会员
    @Published var isPremiumMember: Bool = false
    
    /// 当前购买的产品
    @Published var currentProduct: Product?
    
    // MARK: - Private Properties
    /// 产品更新监听任务
    private var updateListenerTask: Task<Void, Error>?
    
    /// 产品ID列表
    private let productIDs: Set<String> = [IAPProductID.monthlyMembership, IAPProductID.premiumMembership]
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // 启动交易更新监听
        startTransactionListener()
        // 加载已购买状态
        loadPurchaseStatus()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener
    /// 启动交易更新监听
    private func startTransactionListener() {
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }
    
    /// 处理交易更新
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await transaction.finish()
            self.isPremiumMember = true
            self.savePurchaseStatus()
            self.purchaseStatus = .success
            Logger.info("Transaction verified and finished: \(transaction.productID)")
        } catch {
            Logger.error("Transaction verification failed: \(error)")
            self.purchaseStatus = .failed("transaction_verification_failed".localized)
        }
    }
    
    // MARK: - Product Loading
    /// 加载产品列表
    func loadProducts() async {
        purchaseStatus = .loading
        
        // 记录详细信息用于调试
        Logger.info("Attempting to load products with IDs: \(productIDs)")
        Logger.info("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            Logger.info("StoreKit returned \(storeProducts.count) products")
            
            // 详细记录每个产品的信息
            for product in storeProducts {
                Logger.info("Found product: \(product.id), type: \(product.type), price: \(product.displayPrice)")
            }
            
            // 检查哪些产品ID没有找到
            let foundIDs = Set(storeProducts.map { $0.id })
            let missingIDs = productIDs.subtracting(foundIDs)
            if !missingIDs.isEmpty {
                Logger.warning("Missing products for IDs: \(missingIDs)")
                Logger.warning("Possible reasons:")
                Logger.warning("1. Products not yet approved in App Store Connect")
                Logger.warning("2. Products in 'Ready to Submit' status need to be submitted")
                Logger.warning("3. Bundle ID mismatch between app and products")
                Logger.warning("4. Testing in simulator (use real device with sandbox account)")
                Logger.warning("5. Products need time to propagate (can take up to 24 hours)")
            }
            
            self.products = storeProducts
            // 优先选择永久会员，如果没有则选择第一个
            self.currentProduct = storeProducts.first { $0.id == IAPProductID.premiumMembership } ?? storeProducts.first
            
            if storeProducts.isEmpty {
                let errorMsg = "No products found for IDs: \(productIDs). Please check:\n1. Products are approved in App Store Connect\n2. Bundle ID matches: \(Bundle.main.bundleIdentifier ?? "unknown")\n3. Testing on real device with sandbox account"
                Logger.warning(errorMsg)
                self.purchaseStatus = .failed("no_products_available".localized)
            } else {
                Logger.info("Successfully loaded \(storeProducts.count) products")
                self.purchaseStatus = .idle
            }
        } catch {
            let errorDescription = """
            Failed to load products: \(error.localizedDescription)
            Error type: \(type(of: error))
            Product IDs requested: \(productIDs)
            Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")
            """
            Logger.error(errorDescription)
            
            // 提供更具体的错误信息
            var errorMessage = "failed_to_load_products".localized
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .systemError(let code):
                    errorMessage = "StoreKit system error: \(code)"
                case .networkError(let error):
                    errorMessage = "Network error: \(error.localizedDescription)"
                default:
                    errorMessage = storeKitError.localizedDescription
                }
            }
            
            self.purchaseStatus = .failed(errorMessage)
        }
    }
    
    // MARK: - Purchase
    /// 购买产品
    func purchase(_ product: Product) async {
        purchaseStatus = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                self.isPremiumMember = true
                self.savePurchaseStatus()
                self.purchaseStatus = .success
                Logger.info("Purchase successful: \(product.id)")
                
            case .userCancelled:
                self.purchaseStatus = .idle
                Logger.info("User cancelled purchase")
                
            case .pending:
                self.purchaseStatus = .failed("purchase_pending".localized)
                Logger.info("Purchase pending approval")
                
            @unknown default:
                self.purchaseStatus = .failed("unknown_purchase_status".localized)
                Logger.warning("Unknown purchase status")
            }
        } catch {
            Logger.error("Purchase failed: \(error)")
            self.purchaseStatus = .failed("purchase_failed".localized)
        }
    }
    
    // MARK: - Restore Purchases
    /// 恢复购买
    func restorePurchases() async {
        purchaseStatus = .loading
        
        do {
            try await AppStore.sync()
            
            // 检查所有历史交易
            var foundPurchase = false
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    if productIDs.contains(transaction.productID) {
                        foundPurchase = true
                        self.isPremiumMember = true
                        self.savePurchaseStatus()
                        Logger.info("Restored purchase: \(transaction.productID)")
                    }
                } catch {
                    Logger.error("Failed to verify transaction: \(error)")
                }
            }
            
            if foundPurchase {
                self.purchaseStatus = .restored
            } else {
                self.purchaseStatus = .failed("no_purchases_to_restore".localized)
            }
        } catch {
            Logger.error("Failed to restore purchases: \(error)")
            self.purchaseStatus = .failed("restore_failed".localized)
        }
    }
    
    // MARK: - Transaction Verification
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Purchase Status Persistence
    /// 保存购买状态
    private func savePurchaseStatus() {
        UserDefaults.standard.set(isPremiumMember, forKey: "isPremiumMember")
        UserDefaults.standard.synchronize()
    }
    
    /// 加载购买状态
    private func loadPurchaseStatus() {
        isPremiumMember = UserDefaults.standard.bool(forKey: "isPremiumMember")
        
        // 验证当前交易状态
        Task {
            await verifyCurrentEntitlements()
        }
    }
    
    /// 验证当前授权状态
    private func verifyCurrentEntitlements() async {
        var hasValidPurchase = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if productIDs.contains(transaction.productID) {
                    hasValidPurchase = true
                    break
                }
            } catch {
                Logger.error("Failed to verify entitlement: \(error)")
            }
        }
        
        if hasValidPurchase {
            self.isPremiumMember = true
            self.savePurchaseStatus()
        } else if isPremiumMember {
            // 如果本地标记为已购买但验证失败，清除标记
            Logger.warning("Purchase verification failed, clearing local status")
            self.isPremiumMember = false
            self.savePurchaseStatus()
        }
    }
    
    // MARK: - Helper Methods
    /// 获取产品价格字符串
    func priceString(for product: Product) -> String {
        return product.displayPrice
    }
    
    /// 获取产品本地化价格
    func localizedPrice(for product: Product) -> String {
        // StoreKit 2 已提供 displayPrice（本地化后的价格字符串）
        return product.displayPrice
    }
}

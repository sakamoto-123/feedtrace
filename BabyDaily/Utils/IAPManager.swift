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

/// 会员类型枚举
enum MembershipType: String, Codable {
    case lifetime = "lifetime"        // 永久会员
    case subscription = "subscription" // 订阅会员
    
    var localizedName: String {
        switch self {
        case .lifetime:
            return "premium_membership_lifetime".localized
        case .subscription:
            return "premium_membership_monthly".localized
        }
    }
}

/// 会员状态枚举
enum MembershipStatus: String, Codable {
    case active = "active"           // 有效
    case expired = "expired"         // 已过期
    case notSubscribed = "not_subscribed" // 未订阅
    
    var localizedName: String {
        switch self {
        case .active:
            return "membership_active".localized
        case .expired:
            return "membership_expired".localized
        case .notSubscribed:
            return "membership_not_subscribed".localized
        }
    }
}

/// 会员信息模型
struct MembershipInfo: Codable {
    let membershipType: MembershipType
    let purchaseDate: Date
    let expirationDate: Date?
    let productID: String
    let transactionID: String
    
    /// 检查会员是否有效
    var isActive: Bool {
        guard let expirationDate = expirationDate else {
            // 永久会员，始终有效
            return true
        }
        // 订阅会员，检查是否过期
        return expirationDate > Date()
    }
    
    /// 获取会员状态
    var status: MembershipStatus {
        if isActive {
            return .active
        } else {
            return .expired
        }
    }
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
    
    /// 会员信息
    @Published var membershipInfo: MembershipInfo?
    
    /// 会员状态
    @Published var membershipStatus: MembershipStatus = .notSubscribed
    
    /// 会员过期时间（仅订阅会员）
    @Published var expirationDate: Date?
    
    // MARK: - Private Properties
    /// 产品更新监听任务
    private var updateListenerTask: Task<Void, Error>?
    
    /// 产品ID列表
    private let productIDs: Set<String> = [IAPProductID.monthlyMembership, IAPProductID.premiumMembership]
    
    /// Keychain管理器
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // 启动交易更新监听
        startTransactionListener()
        // 加载已购买状态
        loadPurchaseStatus()
        // 启动时检查会员状态
        Task {
            await checkMembershipStatus()
        }
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
            
            Logger.info("Processing transaction update: \(transaction.productID), ID: \(transaction.id)")
            
            // 提取会员信息
            if let membershipInfo = extractMembershipInfo(from: transaction) {
                // 保存到Keychain
                if keychainManager.saveMembershipInfo(membershipInfo) {
                    await MainActor.run {
                        self.membershipInfo = membershipInfo
                        self.isPremiumMember = membershipInfo.isActive
                        self.membershipStatus = membershipInfo.status
                        self.expirationDate = membershipInfo.expirationDate
                    }
                    Logger.info("Membership info updated from transaction: \(transaction.productID), type: \(membershipInfo.membershipType.rawValue)")
                } else {
                    Logger.error("Failed to save membership info to Keychain for transaction: \(transaction.productID)")
                    // 即使Keychain保存失败，也更新内存中的状态
                    await MainActor.run {
                        self.membershipInfo = membershipInfo
                        self.isPremiumMember = membershipInfo.isActive
                        self.membershipStatus = membershipInfo.status
                        self.expirationDate = membershipInfo.expirationDate
                    }
                }
            } else {
                Logger.warning("Failed to extract membership info from transaction: \(transaction.productID)")
                // 即使无法提取会员信息，也标记为会员（基于产品ID）
                if productIDs.contains(transaction.productID) {
                    await MainActor.run {
                        self.isPremiumMember = true
                    }
                }
            }
            
            await transaction.finish()
            await MainActor.run {
                self.purchaseStatus = .success
            }
            Logger.info("Transaction verified and finished: \(transaction.productID)")
        } catch {
            Logger.error("Transaction verification failed: \(error.localizedDescription)")
            await MainActor.run {
                self.purchaseStatus = .failed("transaction_verification_failed".localized)
            }
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
                
                Logger.info("Purchase transaction verified: \(transaction.productID), ID: \(transaction.id)")
                
                // 提取会员信息（临时更新，后续会从服务器验证）
                if let membershipInfo = extractMembershipInfo(from: transaction) {
                    Logger.info("Extracted membership info: type=\(membershipInfo.membershipType.rawValue), active=\(membershipInfo.isActive), expiration=\(membershipInfo.expirationDate?.description ?? "nil")")
                    // 先临时保存到Keychain
                    if keychainManager.saveMembershipInfo(membershipInfo) {
                        self.membershipInfo = membershipInfo
                        self.isPremiumMember = membershipInfo.isActive
                        self.membershipStatus = membershipInfo.status
                        self.expirationDate = membershipInfo.expirationDate
                        Logger.info("Membership info temporarily saved after purchase: \(product.id)")
                    } else {
                        Logger.error("Failed to save membership info to Keychain after purchase")
                    }
                } else {
                    Logger.warning("Failed to extract membership info from transaction: \(transaction.productID)")
                }
                
                await transaction.finish()
                Logger.info("Transaction finished: \(transaction.productID)")
                
                // 购买成功后，等待一小段时间让服务器同步，然后重新验证授权状态
                // 这对于订阅会员尤其重要，因为新购买的订阅可能需要一点时间才能出现在授权列表中
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒
                
                // 重新验证当前授权状态，确保从服务器获取最新的会员信息
                Logger.info("Re-verifying membership status after purchase...")
                await verifyCurrentEntitlements()
                
                self.purchaseStatus = .success
                Logger.info("Purchase successful: \(product.id), membership status updated")
                
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
            let errorMessage: String
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .systemError(let code):
                    errorMessage = "StoreKit system error: \(code)"
                    Logger.error("Purchase failed with system error: \(code)")
                case .networkError(let networkError):
                    errorMessage = "Network error: \(networkError.localizedDescription)"
                    Logger.error("Purchase failed with network error: \(networkError.localizedDescription)")
                case .userCancelled:
                    errorMessage = "purchase_cancelled".localized
                    Logger.info("User cancelled purchase")
                    self.purchaseStatus = .idle
                    return
                default:
                    errorMessage = storeKitError.localizedDescription
                    Logger.error("Purchase failed with StoreKit error: \(storeKitError.localizedDescription)")
                }
            } else {
                errorMessage = error.localizedDescription
                Logger.error("Purchase failed with error: \(error.localizedDescription)")
            }
            self.purchaseStatus = .failed(errorMessage)
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
            var latestMembershipInfo: MembershipInfo?
            
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    if productIDs.contains(transaction.productID) {
                        foundPurchase = true
                        
                        // 提取会员信息
                        if let membershipInfo = extractMembershipInfo(from: transaction) {
                            // 保留最新的会员信息
                            if latestMembershipInfo == nil || 
                               (membershipInfo.purchaseDate > (latestMembershipInfo?.purchaseDate ?? Date.distantPast)) {
                                latestMembershipInfo = membershipInfo
                            }
                        }
                        
                        Logger.info("Restored purchase: \(transaction.productID)")
                    }
                } catch {
                    Logger.error("Failed to verify transaction: \(error)")
                }
            }
            
            if foundPurchase, let membershipInfo = latestMembershipInfo {
                // 保存到Keychain
                if keychainManager.saveMembershipInfo(membershipInfo) {
                    self.membershipInfo = membershipInfo
                    self.isPremiumMember = membershipInfo.isActive
                    self.membershipStatus = membershipInfo.status
                    self.expirationDate = membershipInfo.expirationDate
                    Logger.info("Membership info restored successfully")
                }
                self.purchaseStatus = .restored
            } else if foundPurchase {
                // 找到交易但无法提取会员信息
                self.isPremiumMember = true
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
    
    // MARK: - Membership Info Extraction
    /// 从Transaction中提取会员信息
    private func extractMembershipInfo(from transaction: Transaction) -> MembershipInfo? {
        let productID = transaction.productID
        let purchaseDate = transaction.purchaseDate
        let transactionID = String(transaction.id)
        
        Logger.debug("Extracting membership info from transaction: productID=\(productID), purchaseDate=\(purchaseDate), transactionID=\(transactionID)")
        
        // 判断会员类型
        let membershipType: MembershipType
        if productID == IAPProductID.premiumMembership {
            membershipType = .lifetime
            Logger.debug("Membership type: lifetime")
        } else if productID == IAPProductID.monthlyMembership {
            membershipType = .subscription
            Logger.debug("Membership type: subscription")
        } else {
            Logger.warning("Unknown product ID: \(productID)")
            return nil
        }
        
        // 对于订阅，获取过期时间
        var expirationDate: Date? = nil
        if membershipType == .subscription {
            // StoreKit 2中，订阅Transaction有expirationDate属性
            // 对于订阅产品，过期时间在Transaction的expirationDate中
            if let expiration = transaction.expirationDate {
                expirationDate = expiration
                Logger.info("Subscription expiration date from transaction: \(expiration)")
            } else {
                // 如果没有过期时间（可能是首次购买或续订中），使用购买日期+1个月作为估算
                expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: purchaseDate)
                Logger.warning("No expiration date found in transaction, using estimated date: \(expirationDate?.description ?? "nil")")
                Logger.warning("Note: This is an estimate. Actual expiration will be verified from server.")
            }
        }
        
        let membershipInfo = MembershipInfo(
            membershipType: membershipType,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            productID: productID,
            transactionID: transactionID
        )
        
        Logger.debug("Extracted membership info: type=\(membershipType.rawValue), active=\(membershipInfo.isActive), expiration=\(expirationDate?.description ?? "nil")")
        
        return membershipInfo
    }
    
    // MARK: - Membership Status Check
    /// 检查会员状态
    func checkMembershipStatus() async {
        Logger.info("Checking membership status...")
        
        do {
            // 首先从Keychain加载会员信息
            if let savedInfo = keychainManager.loadMembershipInfo() {
                // 检查是否过期（对于订阅）
                if savedInfo.isActive {
                    // 会员仍然有效
                    self.membershipInfo = savedInfo
                    self.isPremiumMember = true
                    self.membershipStatus = .active
                    self.expirationDate = savedInfo.expirationDate
                    Logger.info("Membership is active from Keychain, type: \(savedInfo.membershipType.rawValue)")
                } else {
                    // 会员已过期，需要验证服务器状态
                    Logger.info("Membership expired in local storage, verifying with server...")
                }
            } else {
                Logger.info("No membership info found in Keychain")
            }
            
            // 验证当前授权状态（与Apple服务器通信）
            await verifyCurrentEntitlements()
        } catch {
            Logger.error("Error checking membership status: \(error.localizedDescription)")
            // 即使检查失败，也尝试从Keychain恢复状态
            if let savedInfo = keychainManager.loadMembershipInfo() {
                self.membershipInfo = savedInfo
                self.isPremiumMember = savedInfo.isActive
                self.membershipStatus = savedInfo.status
                self.expirationDate = savedInfo.expirationDate
                Logger.info("Restored membership status from Keychain after error")
            }
        }
    }
    
    // MARK: - Purchase Status Persistence
    /// 加载购买状态（兼容旧版本）
    private func loadPurchaseStatus() {
        // 从Keychain加载会员信息
        if let membershipInfo = keychainManager.loadMembershipInfo() {
            self.membershipInfo = membershipInfo
            self.isPremiumMember = membershipInfo.isActive
            self.membershipStatus = membershipInfo.status
            self.expirationDate = membershipInfo.expirationDate
            Logger.info("Membership info loaded from Keychain")
        } else {
            // 兼容旧版本：从UserDefaults迁移
            let oldStatus = UserDefaults.standard.bool(forKey: "isPremiumMember")
            if oldStatus {
                Logger.info("Migrating from UserDefaults to Keychain...")
                // 如果UserDefaults中有数据，尝试从服务器验证
                Task {
                    await verifyCurrentEntitlements()
                }
            }
        }
    }
    
    /// 验证当前授权状态
    private func verifyCurrentEntitlements() async {
        Logger.info("Verifying current entitlements with Apple server...")
        
        var latestMembershipInfo: MembershipInfo?
        var hasValidPurchase = false
        var verificationErrors: [Error] = []
        var entitlementCount = 0
        
        do {
            for try await result in Transaction.currentEntitlements {
                entitlementCount += 1
                do {
                    let transaction = try checkVerified(result)
                    Logger.debug("Found entitlement #\(entitlementCount): productID=\(transaction.productID), transactionID=\(transaction.id)")
                    
                    if productIDs.contains(transaction.productID) {
                        hasValidPurchase = true
                        Logger.info("Found valid membership entitlement: \(transaction.productID)")
                        
                        // 对于订阅，记录过期时间
                        if let expirationDate = transaction.expirationDate {
                            Logger.info("Entitlement expiration date: \(expirationDate)")
                        } else {
                            Logger.warning("No expiration date in entitlement for: \(transaction.productID)")
                        }
                        
                        // 提取会员信息
                        if let membershipInfo = extractMembershipInfo(from: transaction) {
                            // 保留最新的会员信息（选择购买日期最新的）
                            if latestMembershipInfo == nil || 
                               (membershipInfo.purchaseDate > (latestMembershipInfo?.purchaseDate ?? Date.distantPast)) {
                                latestMembershipInfo = membershipInfo
                                Logger.info("Updated latest membership info: type=\(membershipInfo.membershipType.rawValue), active=\(membershipInfo.isActive), expiration=\(membershipInfo.expirationDate?.description ?? "nil")")
                            } else {
                                Logger.debug("Keeping existing latest membership info (newer purchase date)")
                            }
                        } else {
                            Logger.warning("Failed to extract membership info from entitlement: \(transaction.productID)")
                            // 即使提取失败，也标记为有有效购买
                        }
                    } else {
                        Logger.debug("Entitlement is not a membership product: \(transaction.productID)")
                    }
                } catch {
                    Logger.error("Failed to verify entitlement: \(error.localizedDescription)")
                    verificationErrors.append(error)
                }
            }
            
            Logger.info("Finished iterating entitlements. Total: \(entitlementCount), Valid membership: \(hasValidPurchase)")
        } catch {
            Logger.error("Error iterating entitlements: \(error.localizedDescription)")
            verificationErrors.append(error)
        }
        
        // 如果有验证错误但找到了有效购买，记录警告但继续处理
        if !verificationErrors.isEmpty && hasValidPurchase {
            Logger.warning("Some entitlements failed verification, but valid purchases found")
        }
        
        if hasValidPurchase {
            if let membershipInfo = latestMembershipInfo {
                // 更新会员信息
                Logger.info("Updating membership status with verified info: type=\(membershipInfo.membershipType.rawValue), active=\(membershipInfo.isActive)")
                if keychainManager.updateMembershipInfo(membershipInfo) {
                    self.membershipInfo = membershipInfo
                    self.isPremiumMember = membershipInfo.isActive
                    self.membershipStatus = membershipInfo.status
                    self.expirationDate = membershipInfo.expirationDate
                    Logger.info("Membership status verified and updated successfully: type=\(membershipInfo.membershipType.rawValue), active=\(membershipInfo.isActive), status=\(membershipInfo.status.rawValue)")
                } else {
                    Logger.error("Failed to update membership info in Keychain, but updating in-memory state")
                    // 即使Keychain更新失败，也更新内存状态
                    self.membershipInfo = membershipInfo
                    self.isPremiumMember = membershipInfo.isActive
                    self.membershipStatus = membershipInfo.status
                    self.expirationDate = membershipInfo.expirationDate
                    Logger.info("Membership status updated in memory: type=\(membershipInfo.membershipType.rawValue), active=\(membershipInfo.isActive)")
                }
            } else {
                // 有有效交易但无法提取会员信息，至少标记为会员
                Logger.warning("Valid purchase found but unable to extract membership info. Marking as premium member anyway.")
                self.isPremiumMember = true
                self.membershipStatus = .active
                // 不清除现有的会员信息，保留之前的状态
            }
        } else {
            // 没有有效购买，清除会员状态
            Logger.info("No valid purchase found in entitlements")
            if self.isPremiumMember {
                Logger.warning("No valid purchase found, clearing membership status")
                self.isPremiumMember = false
                self.membershipStatus = .notSubscribed
                self.membershipInfo = nil
                self.expirationDate = nil
                // 清除Keychain中的旧数据
                if !keychainManager.deleteMembershipInfo() {
                    Logger.warning("Failed to delete membership info from Keychain")
                }
            } else {
                Logger.info("No valid purchase found, user is not a premium member")
            }
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

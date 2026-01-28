//
//  BabyDailyApp.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import SwiftUI
import Combine
import CloudKit
import CoreData

// App Delegate for handling CloudKit Sharing
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let container = CKContainer(identifier: cloudKitShareMetadata.containerIdentifier)
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        acceptSharesOperation.perShareResultBlock = { metadata, result in
            switch result {
            case .success(let share):
                Logger.info("Accepted share: \(share)")
            case .failure(let error):
                Logger.error("Failed to accept share: \(error)")
            }
        }
        
        acceptSharesOperation.acceptSharesResultBlock = { result in
             if case .failure(let error) = result {
                 Logger.error("Accept shares operation failed: \(error)")
             }
        }
        
        container.add(acceptSharesOperation)
    }
}

@main
struct BabyDailyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Core Data Persistence Controller
    let persistenceController = PersistenceController.shared
    
    // 使用@StateObject包装AppSettings实例，统一管理主题和语言
    @StateObject private var appSettings = AppSettings.shared
    // 使用@StateObject包装UserSettingManager实例，处理用户设置
    @StateObject var userSettingManager = UserSettingManager.shared
    // 获取iCloud同步开关状态
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    
    // 标志：是否正在处理迁移，用于防止循环触发
    @State private var isMigrating = false
    
    // CloudKit Error Handler
    @StateObject private var errorHandler = CloudKitErrorHandler.shared
    
    // 初始化方法
    init() {
        // Core Data 已经在 PersistenceController.shared 中初始化
    }
    
    var body: some Scene {
        WindowGroup {
            // 检查是否已有宝宝数据，如果没有则显示宝宝信息创建页面，否则显示首页
            ContentView()
                // 应用主题模式设置
                .preferredColorScheme(appSettings.currentColorScheme)
                // 应用主题颜色设置
                .accentColor(appSettings.currentThemeColor)
                // 将AppSettings设置为环境对象，使所有视图都能访问和观察到它
                .environmentObject(appSettings)
                .withTheme(appSettings)
                // 使用 id 修饰符，当语言变化时强制整个视图层次结构重新创建
                // 这确保所有使用 .localized 的视图都能获取到最新的本地化字符串
                .id(appSettings.language)
                .onAppear {
                    // 应用启动时检查会员状态
                    Task {
                        Logger.info("App launched, checking membership status...")
                        await IAPManager.shared.checkMembershipStatus()
                        // 输出会员信息
                        logMembershipInfo()
                        // 检查订阅提醒
                        SubscriptionReminderManager.shared.checkSubscriptionStatus()
                        
                        // 初始加载用户设置（如果有）
                        // 注意：这里需要传入 managedObjectContext
                        UserSettingManager.shared.setup(modelContext: persistenceController.container.viewContext)
                        
                    }
                }
                .onChange(of: isICloudSyncEnabled) { _, _ in
                    // 当iCloud状态变化时，也检查会员状态（因为可能影响数据同步）
                    Task {
                        await IAPManager.shared.checkMembershipStatus()
                        // 输出会员信息
                        logMembershipInfo()
                    }
                }
                // 注入 Core Data Context
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .alert(item: $errorHandler.currentError) { error in
                    Alert(
                        title: Text(error.title),
                        message: Text(error.message),
                        dismissButton: .default(Text("ok".localized))
                    )
                }
        }
        // 不需要 .modelContainer(sharedModelContainer) 因为我们已经切换到 Core Data
        .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
            // 如果正在迁移中，忽略此次变化（防止循环触发）
            guard !isMigrating else {
                return
            }
            
            // 检查会员状态：如果用户尝试开启iCloud同步但不是会员，则阻止并恢复原状态
            if newValue {
                let membershipManager = MembershipManager.shared
                let isICloudSyncAvailable = membershipManager.isFeatureAvailable(.iCloudSync)
                
                if !isICloudSyncAvailable {
                    // 非会员不能使用iCloud同步，恢复原状态
                    Logger.warning("Non-premium user attempted to enable iCloud sync. Blocking and reverting.")
                    // 直接使用 UserDefaults 设置，避免触发 @AppStorage 的 onChange
                    UserDefaults.standard.set(false, forKey: "isICloudSyncEnabled")
                    return
                }
            }
            
            // Core Data 的 CloudKit 同步是由 NSPersistentCloudKitContainer 自动管理的
            // 我们不能像 SwiftData 那样轻易地“切换容器”。
            // 通常的做法是始终启用 CloudKit Container，但如果没有登录或不允许同步，数据只会留在本地。
            // 或者，我们可以通过重新加载 Persistent Stores 来切换配置，但这对 Core Data 来说是一个比较重的操作。
            // 
            // 鉴于目前架构，我们简化处理：
            // PersistenceController 默认启用了 CloudKit。
            // 这里的开关更多是用于 UI 状态显示和业务逻辑判断。
        }
    }
    
    // MARK: - Helper Methods
    /// 输出会员信息
    private func logMembershipInfo() {
        let iapManager = IAPManager.shared
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        Logger.info("========== 会员信息 ==========")
        Logger.info("是否为高级会员: \(iapManager.isPremiumMember)")
        Logger.info("会员状态: \(iapManager.membershipStatus.rawValue) (\(iapManager.membershipStatus.localizedName))")
        
        if let membershipInfo = iapManager.membershipInfo {
            Logger.info("会员类型: \(membershipInfo.membershipType.rawValue) (\(membershipInfo.membershipType.localizedName))")
            Logger.info("产品ID: \(membershipInfo.productID)")
            Logger.info("交易ID: \(membershipInfo.transactionID)")
            Logger.info("购买日期: \(dateFormatter.string(from: membershipInfo.purchaseDate))")
            
            if let expirationDate = membershipInfo.expirationDate {
                Logger.info("过期日期: \(dateFormatter.string(from: expirationDate))")
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                if daysRemaining > 0 {
                    Logger.info("剩余天数: \(daysRemaining) 天")
                } else {
                    Logger.info("已过期")
                }
            } else {
                Logger.info("过期日期: 永久会员")
            }
            
            Logger.info("会员是否有效: \(membershipInfo.isActive)")
        } else {
            Logger.info("会员信息: 无")
        }
        
        if let expirationDate = iapManager.expirationDate {
            Logger.info("过期时间: \(dateFormatter.string(from: expirationDate))")
        }
        
        Logger.info("=============================")
    }
}

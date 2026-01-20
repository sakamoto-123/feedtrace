//
//  BabyDailyApp.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import SwiftUI
import SwiftData
import Combine

@main
struct BabyDailyApp: App {
    // 使用@StateObject包装AppSettings实例，统一管理主题和语言
    @StateObject private var appSettings = AppSettings.shared
    // 使用@StateObject包装UserSettingManager实例，处理用户设置
    @StateObject var userSettingManager = UserSettingManager.shared
    // 获取iCloud同步开关状态
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    
    // 使用@State包装ModelContainer，以便在iCloud开关变化时重新创建
    @State private var modelContainer: ModelContainer
    // 标志：是否正在处理迁移，用于防止循环触发
    @State private var isMigrating = false
    
    // 初始化方法
    init() {
        // 首先从UserDefaults获取iCloud同步状态
        let isSyncEnabled = UserDefaults.standard.bool(forKey: "isICloudSyncEnabled")
        // 初始创建ModelContainer - 使用CloudSyncManager的API
        let initialContainer = CloudSyncManager.createModelContainer(isICloudSyncEnabled: isSyncEnabled)
        _modelContainer = State(initialValue: initialContainer)
    }
    
    // 计算属性，用于外部访问ModelContainer
    var sharedModelContainer: ModelContainer {
        return modelContainer
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
                // 注意：不需要 .id(isICloudSyncEnabled)
                // 因为 @Query 会自动响应 ModelContainer 的变化，并且 ContentView 中已有 onChange(of: babies) 处理数据更新
        }
        // 使用动态的modelContainer，确保每次变化时都会更新
        .modelContainer(sharedModelContainer)
        .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
            // 如果正在迁移中，忽略此次变化（防止循环触发）
            guard !isMigrating else {
                return
            }
            
            // 标记开始迁移
            isMigrating = true
            
            // 当iCloud开关状态变化时，在后台线程执行数据迁移
            DispatchQueue.global(qos: .userInitiated).async {
                // 保存当前容器的引用
                let oldContainer = self.modelContainer
                
                // 创建新的ModelContainer - 使用CloudSyncManager的API
                let newContainer = CloudSyncManager.createModelContainer(isICloudSyncEnabled: newValue)
                
                // 迁移数据从旧容器到新容器
                let migrationResult = DataMigrationManager.shared.migrateData(from: oldContainer, to: newContainer)
                
                // 在主线程更新modelContainer和相关管理器
                DispatchQueue.main.async {
                    switch migrationResult {
                    case .success(true):
                        // 更新modelContainer
                        self.modelContainer = newContainer
                        // 重置UserSettingManager，确保它使用新的容器
                        let newContext = ModelContext(newContainer)
                        UserSettingManager.shared.setup(modelContext: newContext)
                        // 迁移成功，清除迁移标志
                        self.isMigrating = false
                    case .failure(let error):
                        Logger.error("Migration failed: \(error.localizedDescription)")
                        // 迁移失败，恢复原状态
                        // 直接使用 UserDefaults 设置，避免触发 @AppStorage 的 onChange
                        UserDefaults.standard.set(oldValue, forKey: "isICloudSyncEnabled")
                        // 清除迁移标志（在下一个 run loop 中清除，确保状态已恢复）
                        DispatchQueue.main.async {
                            self.isMigrating = false
                        }
                    default:
                        // 其他情况，清除迁移标志
                        self.isMigrating = false
                        break
                    }
                }
            }
        }
    }
}

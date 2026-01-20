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
                // 添加基于iCloud同步状态的id，确保当同步状态变化时重新加载视图
                .id(isICloudSyncEnabled)
        }
        // 使用动态的modelContainer，确保每次变化时都会更新
        .modelContainer(sharedModelContainer)
        .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
            // 当iCloud开关状态变化时，执行数据迁移（在主线程）
            // 保存当前容器的引用
            let oldContainer = self.modelContainer
            
            // 创建新的ModelContainer - 使用CloudSyncManager的API
            let newContainer = CloudSyncManager.createModelContainer(isICloudSyncEnabled: newValue)
            
            // 迁移数据从旧容器到新容器
            DataMigrationManager.shared.migrateData(from: oldContainer, to: newContainer)
            
            // 更新modelContainer（在主线程）
            self.modelContainer = newContainer
            // 重置UserSettingManager，确保它使用新的容器
            let newContext = ModelContext(newContainer)
            UserSettingManager.shared.setup(modelContext: newContext)
        }
    }
}

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
    // 使用@StateObject包装ThemeManager实例，确保应用能够观察到主题变化
    @StateObject var themeManager = ThemeManager.shared
    // 使用@StateObject包装LanguageManager实例，确保应用能够观察到语言变化
    @StateObject var languageManager = LanguageManager.shared
    // 使用@StateObject包装UserSettingManager实例，处理用户设置
    @StateObject var userSettingManager = UserSettingManager.shared
    // 获取iCloud同步开关状态
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    
    // 使用@State包装ModelContainer，以便在iCloud开关变化时重新创建
    @State private var modelContainer: ModelContainer
    
    // 初始化方法
    init() {
        // 首先从UserDefaults获取iCloud同步状态，避免循环引用
        let isSyncEnabled = UserDefaults.standard.bool(forKey: "isICloudSyncEnabled")
        // 初始创建ModelContainer
        let initialContainer = Self.createModelContainer(isICloudSyncEnabled: isSyncEnabled)
        _modelContainer = State(initialValue: initialContainer)
    }
    
    // 使用静态方法创建ModelContainer，避免初始化顺序问题
    private static func createModelContainer(isICloudSyncEnabled: Bool) -> ModelContainer {
        let schema = Schema([
            Baby.self,
            Record.self,
            UserSetting.self,
        ])
        
        do {
            if isICloudSyncEnabled {
                // CloudKit同步配置
                let cloudConfiguration = ModelConfiguration(
                    "CloudStore", // 使用不同的名称区分存储
                    schema: schema,
                    cloudKitDatabase: .private("iCloud.cn.iizhi.BabyDaily")
                )
                let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])
                print("Created CloudKit ModelContainer")
                return container
            } else {
                // 本地存储配置 - 明确指定不使用CloudKit，使用独立的文件URL
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let localStoreURL = documentsDirectory.appendingPathComponent("LocalStore.sqlite")
                
                let localConfiguration = ModelConfiguration(
                    "LocalStore", // 使用不同的名称区分存储
                    schema: schema,
                    url: localStoreURL
                )
                let container = try ModelContainer(for: schema, configurations: [localConfiguration])
                print("Created Local ModelContainer at URL: \(localStoreURL)")
                return container
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
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
                .preferredColorScheme(themeManager.currentColorScheme)
                // 应用主题颜色设置
                .accentColor(themeManager.currentThemeColor)
                // 将LanguageManager设置为环境对象，使所有视图都能访问和观察到它
                .environmentObject(languageManager)
                // 使用 id 修饰符，当语言变化时强制整个视图层次结构重新创建
                // 这确保所有使用 .localized 的视图都能获取到最新的本地化字符串
                .id(languageManager.selectedLanguage)
                // 添加基于iCloud同步状态的id，确保当同步状态变化时重新加载视图
                .id(isICloudSyncEnabled)
        }
        // 使用动态的modelContainer，确保每次变化时都会更新
        .modelContainer(sharedModelContainer)
        .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
            // 当iCloud开关状态变化时，执行数据迁移（在后台线程）
            Task.detached {
                // 保存当前容器的引用
                let oldContainer = self.modelContainer
                
                // 创建新的ModelContainer
                let newContainer = Self.createModelContainer(isICloudSyncEnabled: newValue)
                
                // 如果是开启iCloud同步，先主动拉取最新数据
                if newValue {
                    let cloudContext = ModelContext(newContainer)
                    do {
                        // 主动拉取iCloud最新数据
                        try CloudSyncManager.shared.fetchLatestDataFromiCloud(modelContext: cloudContext)
                        // 等待一小段时间，确保SwiftData有足够时间同步
                        try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1秒
                    } catch {
                        print("Failed to fetch latest data from iCloud: \(error)")
                    }
                }
                
                // 迁移数据从旧容器到新容器
                await DataMigrationManager.shared.migrateData(from: oldContainer, to: newContainer)
                
                // 添加全局去重步骤，确保不会有重复数据
                await DataMigrationManager.shared.removeDuplicates(in: newContainer)
                
                // 更新modelContainer（在主线程）
                await MainActor.run {
                    self.modelContainer = newContainer
                    // 重置UserSettingManager，确保它使用新的容器
                    let newContext = ModelContext(newContainer)
                    UserSettingManager.shared.setup(modelContext: newContext)
                }
            }
        }
    }
}

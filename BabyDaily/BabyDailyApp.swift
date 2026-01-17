//
//  BabyDailyApp.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import SwiftUI
import SwiftData

@main
struct BabyDailyApp: App {
    // 使用@StateObject包装ThemeManager实例，确保应用能够观察到主题变化
    @StateObject var themeManager = ThemeManager.shared
    // 使用@StateObject包装LanguageManager实例，确保应用能够观察到语言变化
    @StateObject var languageManager = LanguageManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Baby.self,
            Record.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
        }
        .modelContainer(sharedModelContainer)
    }
}

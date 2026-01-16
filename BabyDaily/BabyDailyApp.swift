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
    // 使用ThemeManager来管理主题
    let themeManager = ThemeManager.shared
    
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
        }
        .modelContainer(sharedModelContainer)
    }
}

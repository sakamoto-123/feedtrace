//
//  ThemeEnvironment.swift
//  BabyDaily
//
//  主题环境值和便捷访问扩展
//

import SwiftUI

// MARK: - 主题环境值
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppSettings.shared
}

extension EnvironmentValues {
    /// 主题设置环境值
    var theme: AppSettings {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - 便捷的View扩展
extension View {
    /// 应用主题设置
    func withTheme(_ settings: AppSettings) -> some View {
        self.environment(\.theme, settings)
    }
    
    /// 根据颜色方案获取背景色
    func themeBackground(for colorScheme: ColorScheme?) -> Color {
        return Color.themeBackground(for: colorScheme)
    }
    
    /// 根据颜色方案获取卡片背景色
    func themeCardBackground(for colorScheme: ColorScheme?) -> Color {
        return Color.themeCardBackground(for: colorScheme)
    }
    
    /// 根据颜色方案获取列表背景色
    func themeListBackground(for colorScheme: ColorScheme?) -> Color {
        return Color.themeListBackground(for: colorScheme)
    }
}

// MARK: - 颜色方案环境值
struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    /// 当前颜色方案
    var appColorScheme: ColorScheme? {
        get { self[ColorSchemeKey.self] }
        set { self[ColorSchemeKey.self] = newValue }
    }
}

// MARK: - 主题颜色辅助扩展
extension Color {
    /// 根据当前主题获取背景色
    static func themeBackground(for colorScheme: ColorScheme?) -> Color {
        guard let colorScheme = colorScheme else {
            // 如果colorScheme为nil，使用系统当前的颜色方案
            return Color(uiColor: .systemBackground)
        }
        
        switch colorScheme {
        case .light:
            return Color(uiColor: .systemBackground)
        case .dark:
            return Color(uiColor: .systemGray6)
        @unknown default:
            return Color(uiColor: .systemBackground)
        }
    }
    
    /// 根据当前主题获取卡片背景色
    static func themeCardBackground(for colorScheme: ColorScheme?) -> Color {
        guard let colorScheme = colorScheme else {
            return Color(uiColor: .secondarySystemBackground)
        }
        
        switch colorScheme {
        case .light:
            return Color.white
        case .dark:
            return Color(uiColor: .systemGray6)
        @unknown default:
            return Color(uiColor: .secondarySystemBackground)
        }
    }
    
    /// 根据当前主题获取列表背景色
    static func themeListBackground(for colorScheme: ColorScheme?) -> Color {
        guard let colorScheme = colorScheme else {
            return Color(uiColor: .systemGroupedBackground)
        }
        
        switch colorScheme {
        case .light:
            return Color(uiColor: .systemGray6)
        case .dark:
            return Color.black
        @unknown default:
            return Color(uiColor: .systemGroupedBackground)
        }
    }
}

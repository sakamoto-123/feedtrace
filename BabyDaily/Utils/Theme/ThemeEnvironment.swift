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

// MARK: - 十六进制颜色扩展
extension Color {
    /// 从十六进制字符串创建Color
    static func fromHex(_ hex: String) -> Color {
        let hexString = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        guard hexString.count == 6, let hexValue = UInt32(hexString, radix: 16) else {
            return .gray
        }
        
        let red = Double((hexValue & 0xFF0000) >> 16) / 255.0
        let green = Double((hexValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(hexValue & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
    
    /// 从十六进制字符串初始化Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (a, r, g, b): (Int, Int, Int, Int)
        if hex.count == 8 {
            a = Int(int >> 24) & 0xff
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else if hex.count == 6 {
            a = 255
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else {
            a = 255
            r = 0
            g = 0
            b = 0
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
            return Color.accentColor.opacity(0.15)
        case .dark:
            return Color(uiColor: .black)
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

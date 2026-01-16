import SwiftUI
import Combine

// 主题模式枚举
enum ThemeMode: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色模式"
    case dark = "深色模式"
    
    // 转换为SwiftUI的ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // 跟随系统
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// 主题颜色枚举
enum ThemeColor: String, CaseIterable, Identifiable {
    case blue = "蓝色"
    case green = "绿色"
    case purple = "紫色"
    case pink = "粉色"
    case orange = "橙色"
    case red = "红色"
    
    var id: String {
        return self.rawValue
    }
    
    // 转换为SwiftUI的Color
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .green:
            return .green
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .orange:
            return .orange
        case .red:
            return .red
        }
    }
}

// 主题管理工具类
class ThemeManager: ObservableObject {
    // 使用@AppStorage持久化主题设置，默认跟随系统
    @AppStorage("selectedThemeMode") var selectedThemeMode: ThemeMode = .system
    
    // 使用@AppStorage持久化主题颜色设置，默认蓝色
    @AppStorage("selectedThemeColor") var selectedThemeColor: ThemeColor = .blue
    
    // 单例实例
    static let shared = ThemeManager()
    
    private init() {}
    
    // 切换主题模式
    func switchTheme(to mode: ThemeMode) {
        selectedThemeMode = mode
    }
    
    // 切换主题颜色
    func switchThemeColor(to color: ThemeColor) {
        selectedThemeColor = color
    }
    
    // 获取当前主题模式对应的ColorScheme
    var currentColorScheme: ColorScheme? {
        return selectedThemeMode.colorScheme
    }
    
    // 获取当前主题颜色
    var currentThemeColor: Color {
        return selectedThemeColor.color
    }
}

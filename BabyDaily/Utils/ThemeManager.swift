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
    // 使用@Published属性来触发视图更新
    @Published var selectedThemeMode: ThemeMode {
        didSet {
            // 当主题模式改变时，更新AppStorage的值
            UserDefaults.standard.set(selectedThemeMode.rawValue, forKey: "selectedThemeMode")
        }
    }
    
    @Published var selectedThemeColor: ThemeColor {
        didSet {
            // 当主题颜色改变时，更新AppStorage的值
            UserDefaults.standard.set(selectedThemeColor.rawValue, forKey: "selectedThemeColor")
        }
    }
    
    // 单例实例
    static let shared = ThemeManager()
    
    private init() {
        // 从AppStorage中读取保存的值，如果没有则使用默认值
        let savedMode = UserDefaults.standard.string(forKey: "selectedThemeMode") ?? ThemeMode.system.rawValue
        self.selectedThemeMode = ThemeMode(rawValue: savedMode) ?? .system
        
        let savedColor = UserDefaults.standard.string(forKey: "selectedThemeColor") ?? ThemeColor.blue.rawValue
        self.selectedThemeColor = ThemeColor(rawValue: savedColor) ?? .blue
    }
    
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

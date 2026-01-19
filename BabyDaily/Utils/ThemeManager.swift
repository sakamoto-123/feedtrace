import SwiftUI
import Combine
import SwiftData

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
    case lightYellow = "浅黄色"
    case lightPurple = "浅紫色"
    case skyBlue = "天蓝色"
    case paleBlue = "淡蓝色"
    case grayBlue = "灰蓝色"
    case brown = "棕色"
    case deepBlue = "深蓝色"
    case lavender = "薰衣草紫"
    case teal = "青绿色"
    case mintGreen = "薄荷绿"
    case darkGreen = "深绿色"
    case yellowGreen = "黄绿色"
    case beige = "米色"
    case emeraldGreen = "翠绿色"
    case magenta = "紫红色"
    case gray = "灰色"
    case aquaGreen = "水绿色"
    case peach = "桃色"
    case coral = "珊瑚色"
    case taupe = "灰褐色"
    case slateBlue = "蓝灰色"
    case violet = "紫罗兰色"
    case lightPink = "浅粉色"
    
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
        case .lightYellow:
            return Color.fromHex("#ffc76b")
        case .lightPurple:
            return Color.fromHex("#b0a4e3")
        case .skyBlue:
            return Color.fromHex("#b7dbff")
        case .paleBlue:
            return Color.fromHex("#aad9f2")
        case .grayBlue:
            return Color.fromHex("#87a8c3")
        case .brown:
            return Color.fromHex("#955539")
        case .deepBlue:
            return Color.fromHex("#4b9be1")
        case .lavender:
            return Color.fromHex("#cea6e3")
        case .teal:
            return Color.fromHex("#88ada6")
        case .mintGreen:
            return Color.fromHex("#b9dec9")
        case .darkGreen:
            return Color.fromHex("#84ae64")
        case .yellowGreen:
            return Color.fromHex("#b7d07a")
        case .beige:
            return Color.fromHex("#EBCDA8")
        case .emeraldGreen:
            return Color.fromHex("#55bb8a")
        case .magenta:
            return Color.fromHex("#ad6598")
        case .gray:
            return Color.fromHex("#b2bbbe")
        case .aquaGreen:
            return Color.fromHex("#6cb09e")
        case .peach:
            return Color.fromHex("#ffb658")
        case .coral:
            return Color.fromHex("#ff9066")
        case .taupe:
            return Color.fromHex("#b19f8f")
        case .slateBlue:
            return Color.fromHex("#a7a8bd")
        case .violet:
            return Color.fromHex("#ae88c3")
        case .lightPink:
            return Color.fromHex("#ffbeba")
        }
    }
}

// 主题管理工具类
class ThemeManager: ObservableObject {
    // 使用@Published属性来触发视图更新
    @Published var selectedThemeMode: ThemeMode {
        didSet {
            // 当主题模式改变时，更新UserSetting模型
            Task {
                await updateUserSetting { [self] setting in
                    setting.themeMode = selectedThemeMode.rawValue
                }
            }
        }
    }
    
    @Published var selectedThemeColor: ThemeColor {
        didSet {
            // 当主题颜色改变时，更新UserSetting模型
            Task {
                await updateUserSetting { [self] setting in
                    setting.themeColor = selectedThemeColor.rawValue
                }
            }
        }
    }
    
    // 单例实例
    static let shared = ThemeManager()
    
    private init() {
        // 从UserDefaults中读取保存的值，如果没有则使用默认值
        let savedMode = UserDefaults.standard.string(forKey: "selectedThemeMode") ?? ThemeMode.system.rawValue
        self.selectedThemeMode = ThemeMode(rawValue: savedMode) ?? .system
        
        let savedColor = UserDefaults.standard.string(forKey: "selectedThemeColor") ?? ThemeColor.blue.rawValue
        self.selectedThemeColor = ThemeColor(rawValue: savedColor) ?? .blue
    }
    
    // 获取或创建UserSetting实例
    private func getUserSetting() async -> UserSetting? {
        // 这里需要访问ModelContext，暂时返回nil
        // 实际实现会在App启动后初始化
        return nil
    }
    
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        // 这里需要访问ModelContext，暂时不实现
        // 实际实现会在App启动后初始化
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

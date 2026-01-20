//
//  AppSettings.swift
//  BabyDaily
//
//  统一的应用程序设置管理器
//  整合主题、语言等所有设置，遵循iOS最佳实践
//

import SwiftUI
import Combine
import SwiftData

// MARK: - 主题模式枚举
enum ThemeMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    /// 转换为SwiftUI的ColorScheme
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
    
    /// 本地化显示名称
    var localizedName: String {
        switch self {
        case .system:
            return "system_theme".localized
        case .light:
            return "light_theme".localized
        case .dark:
            return "dark_theme".localized
        }
    }
}

// MARK: - 主题颜色枚举
enum ThemeColor: String, CaseIterable, Identifiable, Codable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case pink = "pink"
    case orange = "orange"
    case red = "red"
    case lightYellow = "lightYellow"
    case lightPurple = "lightPurple"
    case skyBlue = "skyBlue"
    case paleBlue = "paleBlue"
    case grayBlue = "grayBlue"
    case brown = "brown"
    case deepBlue = "deepBlue"
    case lavender = "lavender"
    case teal = "teal"
    case mintGreen = "mintGreen"
    case darkGreen = "darkGreen"
    case yellowGreen = "yellowGreen"
    case beige = "beige"
    case emeraldGreen = "emeraldGreen"
    case magenta = "magenta"
    case gray = "gray"
    case aquaGreen = "aquaGreen"
    case peach = "peach"
    case coral = "coral"
    case taupe = "taupe"
    case slateBlue = "slateBlue"
    case violet = "violet"
    case lightPink = "lightPink"
    
    var id: String {
        return self.rawValue
    }
    
    /// 转换为SwiftUI的Color
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

// MARK: - 语言枚举
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = ""
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case portuguese = "pt"
    case spanish = "es"
    
    var id: String {
        return self.rawValue
    }
    
    /// 语言显示名称（使用本地化）
    var displayName: String {
        switch self {
        case .system:
            return "system_language".localized
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .french:
            return "Français"
        case .portuguese:
            return "Português"
        case .spanish:
            return "Español"
        }
    }
}

// MARK: - 统一的应用设置管理器
class AppSettings: ObservableObject {
    // MARK: - 单例
    static let shared = AppSettings()
    
    // MARK: - Published Properties
    @Published var themeMode: ThemeMode
    @Published var themeColor: ThemeColor
    @Published var language: AppLanguage
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let themeMode = "app.themeMode"
        static let themeColor = "app.themeColor"
        static let language = "app.language"
    }
    
    // MARK: - 初始化
    private init() {
        // 从UserDefaults加载设置，优先使用新键，如果没有则尝试旧键（向后兼容）
        let savedThemeMode = UserDefaults.standard.string(forKey: Keys.themeMode) 
            ?? ThemeMode.system.rawValue
        
        // 处理旧格式（中文）到新格式（英文）的转换
        let themeModeValue: String
        switch savedThemeMode {
        case "跟随系统", "system":
            themeModeValue = ThemeMode.system.rawValue
        case "浅色模式", "light":
            themeModeValue = ThemeMode.light.rawValue
        case "深色模式", "dark":
            themeModeValue = ThemeMode.dark.rawValue
        default:
            themeModeValue = savedThemeMode
        }
        self.themeMode = ThemeMode(rawValue: themeModeValue) ?? .system
        
        let savedThemeColor = UserDefaults.standard.string(forKey: Keys.themeColor)
            ?? ThemeColor.blue.rawValue
        
        // 处理旧格式（中文）到新格式（英文）的转换
        let themeColorValue: String
        if let color = ThemeColor(rawValue: savedThemeColor) {
            themeColorValue = savedThemeColor
        } else {
            // 尝试从中文名称映射到英文键
            themeColorValue = Self.mapChineseColorToKey(savedThemeColor) ?? ThemeColor.blue.rawValue
        }
        self.themeColor = ThemeColor(rawValue: themeColorValue) ?? .blue
        
        let savedLanguage = UserDefaults.standard.string(forKey: Keys.language)
            ?? ""
        self.language = AppLanguage(rawValue: savedLanguage) ?? .system
    }
    
    // MARK: - 辅助方法
    /// 将中文颜色名称映射到英文键
    private static func mapChineseColorToKey(_ chineseName: String) -> String? {
        let mapping: [String: String] = [
            "蓝色": "blue",
            "绿色": "green",
            "紫色": "purple",
            "粉色": "pink",
            "橙色": "orange",
            "红色": "red",
            "浅黄色": "lightYellow",
            "浅紫色": "lightPurple",
            "天蓝色": "skyBlue",
            "淡蓝色": "paleBlue",
            "灰蓝色": "grayBlue",
            "棕色": "brown",
            "深蓝色": "deepBlue",
            "薰衣草紫": "lavender",
            "青绿色": "teal",
            "薄荷绿": "mintGreen",
            "深绿色": "darkGreen",
            "黄绿色": "yellowGreen",
            "米色": "beige",
            "翠绿色": "emeraldGreen",
            "紫红色": "magenta",
            "灰色": "gray",
            "水绿色": "aquaGreen",
            "桃色": "peach",
            "珊瑚色": "coral",
            "灰褐色": "taupe",
            "蓝灰色": "slateBlue",
            "紫罗兰色": "violet",
            "浅粉色": "lightPink"
        ]
        return mapping[chineseName]
    }
    
    // MARK: - 主题设置
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        let modeValue = mode.rawValue
        UserDefaults.standard.set(modeValue, forKey: Keys.themeMode)
    }
    
    func setThemeColor(_ color: ThemeColor) {
        themeColor = color
        let colorValue = color.rawValue
        UserDefaults.standard.set(colorValue, forKey: Keys.themeColor)
    }
    
    // MARK: - 语言设置
    func setLanguage(_ language: AppLanguage) {
        self.language = language
        let languageToSave = language == .system ? "" : language.rawValue
        UserDefaults.standard.set(languageToSave, forKey: Keys.language)
    }
    
    // MARK: - 计算属性
    /// 当前颜色方案
    var currentColorScheme: ColorScheme? {
        return themeMode.colorScheme
    }
    
    /// 当前主题颜色
    var currentThemeColor: Color {
        return themeColor.color
    }
    
    /// 当前语言代码
    var currentLanguageCode: String {
        if language == .system {
            return Locale.preferredLanguages.first ?? "en"
        }
        return language.rawValue
    }
    
    /// 当前语言环境
    var currentLocale: Locale {
        return Locale(identifier: currentLanguageCode)
    }
}

// MARK: - Environment Key
struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings.shared
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}

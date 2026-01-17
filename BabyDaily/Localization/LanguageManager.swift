import SwiftUI
import Combine

// 语言枚举
enum AppLanguage: String, CaseIterable, Identifiable {
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
    
    // 语言显示名称
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁体中文"
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

// 语言管理工具类
class LanguageManager: ObservableObject {
    // 单例实例
    static let shared = LanguageManager()
    
    // 语言设置存储键
    private let languageKey = "appLanguage"
    
    // 发布属性，用于观察语言变化
    @Published var selectedLanguage: AppLanguage = .system
    
    private init() {
        loadSettings()
    }
    
    // 加载语言设置
    private func loadSettings() {
        let savedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? ""
        if savedLanguage.isEmpty {
            selectedLanguage = .system
        } else if let language = AppLanguage(rawValue: savedLanguage) {
            selectedLanguage = language
        }
    }
    
    // 保存语言设置
    private func saveSettings() {
        // 如果是系统语言，保存空字符串
        let languageToSave = selectedLanguage == .system ? "" : selectedLanguage.rawValue
        UserDefaults.standard.set(languageToSave, forKey: languageKey)
    }
    
    // 切换语言
    func switchLanguage(to language: AppLanguage) {
        selectedLanguage = language
        saveSettings()
    }
    
    // 获取当前语言代码
    var currentLanguageCode: String {
        if selectedLanguage == .system {
            return Locale.preferredLanguages.first ?? "en"
        }
        return selectedLanguage.rawValue
    }
    
    // 获取当前语言环境
    var currentLocale: Locale {
        return Locale(identifier: currentLanguageCode)
    }
    
    // 获取本地化日期格式
    func localizedDateFormatter(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }
    
    // 获取本地化日期格式字符串
    func localizedDateString(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        return localizedDateFormatter(dateStyle: dateStyle, timeStyle: timeStyle).string(from: date)
    }
}

// 便捷的字符串扩展，用于获取本地化字符串
extension String {
    var localized: String {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        
        if language.isEmpty {
            return NSLocalizedString(self, comment: "")
        }
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: [CVarArg]) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// 视图修饰符，用于让视图能够响应语言变化
extension View {
    func observeLanguage() -> some View {
        self.modifier(LanguageObserver())
    }
}

// 语言观察者修饰符
struct LanguageObserver: ViewModifier {
    @EnvironmentObject var languageManager: LanguageManager
    
    func body(content: Content) -> some View {
        content
            .id(languageManager.selectedLanguage) // 使用 id 修饰符强制视图在语言变化时重新创建
    }
}

// 通知扩展
extension Notification.Name {
    static let languageDidChange = Notification.Name("LanguageDidChangeNotification")
}
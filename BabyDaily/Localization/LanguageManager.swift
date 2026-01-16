import SwiftUI
import Combine

// 语言枚举
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system_language"
    case simplifiedChinese = "simplified_chinese"
    case traditionalChinese = "traditional_chinese"
    case english = "english"
    case japanese = "japanese"
    case korean = "korean"
    case french = "french"
    case portuguese = "portuguese"
    case spanish = "spanish"
    
    var id: String {
        return self.rawValue
    }
    
    // 本地化语言名称
    var localizedName: String {
        return self.rawValue.localized
    }
}

// 语言管理工具类
class LanguageManager: ObservableObject {
    // 使用@AppStorage持久化语言设置，默认跟随系统
    @AppStorage("selectedLanguage") var selectedLanguage: AppLanguage = .system {
        willSet {
            objectWillChange.send()
        }
    }
    
    // 单例实例
    static let shared = LanguageManager()
    
    private init() {}
    
    // 符合ObservableObject协议的objectWillChange发布者
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    // 切换语言
    func switchLanguage(to language: AppLanguage) {
        selectedLanguage = language
    }
    
    // 获取当前语言的标识符
    var currentLanguageCode: String? {
        switch selectedLanguage {
        case .system:
            return nil // 跟随系统
        case .simplifiedChinese:
            return "zh-Hans"
        case .traditionalChinese:
            return "zh-Hant"
        case .english:
            return "en"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        case .french:
            return "fr"
        case .portuguese:
            return "pt"
        case .spanish:
            return "es"
        }
    }
    
    // 获取当前语言环境
    var currentLocale: Locale {
        if let code = currentLanguageCode {
            return Locale(identifier: code)
        } else {
            return Locale.current
        }
    }
    
    // 获取本地化字符串
    func localizedString(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    // 获取带参数的本地化字符串
    func localizedString(_ key: String, arguments: [CVarArg], comment: String = "") -> String {
        return String(format: localizedString(key, comment: comment), arguments: arguments)
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
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: [CVarArg]) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// 视图修饰符，用于监听语言变化
extension View {
    func onLanguageChange(perform action: @escaping () -> Void) -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                action()
            }
    }
}
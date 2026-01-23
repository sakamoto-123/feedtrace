//
//  LanguageManager.swift
//  BabyDaily
//
//  本地化字符串管理
//  提供统一的本地化字符串访问接口
//

import SwiftUI
import Foundation

// MARK: - 本地化字符串扩展
extension String {
    /// 获取本地化字符串
    var localized: String {
        // 使用AppSettings获取当前语言
        let languageCode = AppSettings.shared.currentLanguageCode
        
        // 如果语言代码为空或者是系统语言，使用默认本地化
        if languageCode.isEmpty || languageCode == Locale.preferredLanguages.first {
            return NSLocalizedString(self, comment: "")
        }
        
        // 尝试从指定语言的bundle中获取本地化字符串
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            // 获取默认bundle中的值（用于比较）
            let defaultString = NSLocalizedString(self, comment: "")
            // 从指定语言的bundle中获取值
            let localizedString = bundle.localizedString(forKey: self, value: nil, table: nil)
            
            // 如果指定语言bundle中的值与默认bundle中的值不同，说明找到了正确的翻译
            if localizedString != defaultString {
                return localizedString
            }
            
            // 如果两者相同，需要进一步判断：
            // 1. 如果指定语言bundle中的值与key相同，且默认bundle中的值也与key相同
            //    这可能意味着两个bundle中都没有这个key，或者都有这个key但值都是key本身
            // 2. 为了确保使用正确的语言，我们需要检查：如果指定语言bundle存在，
            //    并且我们明确选择了这个语言，那么应该使用该bundle中的值
            // 3. 但如果默认值来自系统语言（可能是中文），而指定语言是英语，
            //    那么即使值相同，我们也应该使用指定语言bundle中的值
            
            // 更简单的方法：如果找到了指定语言的bundle，就使用它的值
            // 因为如果key不存在，localizedString会返回key本身，但这是该语言bundle的行为
            // 如果key存在但值与key相同（如英语中"nursing"="nursing"），也应该使用它
            return localizedString
        }
        
        // 回退到默认本地化
        return NSLocalizedString(self, comment: "")
    }
    
    /// 使用参数格式化本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - 日期格式化扩展
extension AppSettings {
    /// 获取本地化日期格式化器
    func localizedDateFormatter(
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }
    
    /// 获取本地化日期字符串
    func localizedDateString(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        return localizedDateFormatter(dateStyle: dateStyle, timeStyle: timeStyle).string(from: date)
    }
}
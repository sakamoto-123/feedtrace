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
            let localizedString = bundle.localizedString(forKey: self, value: nil, table: nil)
            // 如果返回的字符串与key相同，说明没有找到翻译，使用默认本地化
            if localizedString != self {
                return localizedString
            }
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
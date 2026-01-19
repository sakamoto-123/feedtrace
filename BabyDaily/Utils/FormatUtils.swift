//
//  FormatUtils.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/17.
//

import Foundation
import SwiftUI

/// NumberFormatter扩展，提供智能小数格式化
extension NumberFormatter {
    /// 智能小数格式化器，移除尾随零和不必要的小数点
    static let smartDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter
    }()
}

/// Double扩展，提供智能格式化
extension Double {
    /// 智能格式化字符串，移除尾随零和不必要的小数点
    var smartDecimal: String {
        NumberFormatter.smartDecimal.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// 智能格式化字符串，带四舍五入到指定小数位数
    /// - Parameter roundedTo: 要四舍五入到的小数位数
    /// - Returns: 智能格式化后的字符串
    func smartDecimal(roundedTo places: Int) -> String {
        let roundedValue = self.rounded(toPlaces: places)
        return NumberFormatter.smartDecimal.string(from: NSNumber(value: roundedValue)) ?? "\(roundedValue)"
    }
}

/// Text扩展，直接使用智能格式化
extension Text {
    /// 创建带有智能格式化Double值的Text视图
    static func smart(_ value: Double) -> Text {
        let text = NumberFormatter.smartDecimal.string(from: NSNumber(value: value)) ?? ""
        return Text(text)
    }
}

/// 格式化日期为相对时间或长格式
/// - Parameter date: 要格式化的日期
/// - Returns: 格式化后的日期字符串
func formatDate(_ date: Date) -> String {
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date, to: now)
    
    if components.day == 0 {
        return "today".localized
    } else if components.day == 1 {
        return "yesterday".localized
    } else {
        return date.formatted(Date.FormatStyle(date: .long).locale(LanguageManager.shared.currentLocale))
    }
}

/// 根据宝宝出生日期计算年龄
/// - Parameters:
///   - baby: 宝宝对象
///   - date: 用于计算年龄的日期，默认使用当前日期
/// - Returns: 格式化后的年龄字符串
func calculateBabyAge(_ baby: Baby, _ date: Date = Date()) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: baby.birthday, to: date)
    
    if let years = components.year, years > 0 {
        if let months = components.month, months > 0 {
            return "\(years)\("year".localized)\(months)\("month".localized)"
        } else {
            return "\(years)\("year".localized)"
        }
    } else if let months = components.month, months > 0 {
        if let days = components.day, days > 0 {
            return "\(months)\("month".localized)\(days)\("day".localized)"
        } else {
            return "\(months)\("month".localized)"
        }
    } else if let days = components.day {
        return "\(days)\("day".localized)"
    } else {
        return "0\("day".localized)"
    }
}

/// 格式化相对时间
/// - Parameter timestamp: 要格式化的时间戳
/// - Returns: 格式化后的相对时间字符串（如：32秒前、3分钟前、1小时前、3个月前、1年前等）
func formatRelativeTime(_ timestamp: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = LanguageManager.shared.currentLocale
    formatter.dateTimeStyle = .numeric
    formatter.unitsStyle = .full
    return formatter.localizedString(for: timestamp, relativeTo: Date())
}

/// 格式化日期时间
/// - Parameters:
///   - date: 要格式化的日期
///   - dateStyle: 日期样式
///   - timeStyle: 时间样式
/// - Returns: 格式化后的日期时间字符串，使用app内选择的语言
func formatDateTime(_ date: Date, dateStyle: Date.FormatStyle.DateStyle = .long, timeStyle: Date.FormatStyle.TimeStyle = .shortened) -> String {
    let formatStyle = Date.FormatStyle(date: dateStyle, time: timeStyle)
        .locale(LanguageManager.shared.currentLocale)
    return date.formatted(formatStyle)
}

/// 格式化两个日期之间的总时间
/// - Parameters:
///   - start: 开始日期
///   - end: 结束日期
/// - Returns: 格式化后的时间间隔字符串，使用app内选择的语言
func localizedDuration(from start: Date, to end: Date) -> String {
    let interval = max(end.timeIntervalSince1970 - start.timeIntervalSince1970, 0)
    
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month,.hour, .minute]   // 允许显示的单位
    formatter.unitsStyle = .full                          // full/short/abbreviated
    formatter.zeroFormattingBehavior = .dropAll          // 不显示0单位
    
    // 设置日历和本地化
    var calendar = Calendar.current
    calendar.locale = LanguageManager.shared.currentLocale
    formatter.calendar = calendar
    
    return formatter.string(from: interval) ?? ""
}

/// 根据记录类型格式化记录内容
/// - Parameter record: 要格式化的记录对象
/// - Returns: 格式化后的记录内容字符串
func formatRecordContent(_ record: Record) -> String {
    switch record.subCategory {
    case "nursing":
        if let end = record.endTimestamp {
            let duration = end.timeIntervalSince(record.startTimestamp)
            let minutes = Int(duration / 60)
            return "left".localized + " \(minutes/2) " + "minutes".localized + "，" + "right".localized + " \(minutes/2) " + "minutes".localized
        } else {
            return "in_progress".localized
        }
    case "vaccination", "medical_visit":
        if let name = record.name {
            return name.localized
        } else {
            return ""
        }
    case "diaper":
        if let excrementStatus = record.excrementStatus {
            return excrementStatus.localized
        } else {
            return ""
        }
    case "medication", "supplement":
        if let name = record.name, let value = record.value, let unit = record.unit {
            return "\(name) \(value.smartDecimal)\(unit.localized)"
        } else {
            return ""
        }
    case "solid_food":
        if let name = record.name, let value = record.value, let unit = record.unit {
            return "\(name) \(value.smartDecimal)\(unit.localized)"
        } else {
            return ""
        }
    case "formula", "water_intake", "breast_milk", "weight", "height", "head":
        if let value = record.value, let unit = record.unit {
            return "\(value.smartDecimal)\(unit.localized)"
        } else {
            return ""
        }
    case "sleep", "pumping":
        if let end = record.endTimestamp {
            let duration = end.timeIntervalSince(record.startTimestamp)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            if hours > 0 {
                return "\(hours)" + "hours".localized + "\(minutes)" + "minutes".localized
            } else {
                return "\(minutes)" + "minutes".localized
            }
        } else {
            return "in_progress".localized
        }
    case "first_tooth", "first_crawl", "first_sit", "first_word", "first_roll":
        return "🎉🎉🎉"

    default:
        return ""
    }
}

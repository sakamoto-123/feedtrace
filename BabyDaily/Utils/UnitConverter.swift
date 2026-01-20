//
//  UnitConverter.swift
//  BabyDaily
//
//  Created on 2026/1/17.
//

import Foundation

/// 单位换算工具类
public struct UnitConverter {
    
    /// 将容量单位转换为毫升（ml）
    /// - Parameters:
    ///   - value: 原始值
    ///   - unit: 单位字符串（如 "ml", "oz" 等）
    /// - Returns: 转换为毫升后的整数值
    public static func convertVolumeToMl(value: Double, unit: String?) -> Int {
        guard let unit = unit?.lowercased() else {
            // 如果没有单位，假设已经是 ml
            return Int(value)
        }
        
        switch unit {
        case "ml", "毫升":
            return Int(value)
        case "oz", "fl oz", "floz", "盎司":
            // 1 美制液体盎司 = 29.5735 毫升
            return Int(value * 29.5735)
        case "l", "liter", "litre", "升":
            // 1 升 = 1000 毫升
            return Int(value * 1000)
        case "cup", "杯":
            // 1 美制杯 = 236.588 毫升
            return Int(value * 236.588)
        default:
            // 未知单位，假设已经是 ml
            Logger.warning("UnitConverter: Unknown volume unit '\(unit)', assuming ml")
            return Int(value)
        }
    }
    
    /// 将重量单位转换为千克（kg）
    /// - Parameters:
    ///   - value: 原始值
    ///   - unit: 单位字符串（如 "kg", "lb", "oz" 等）
    /// - Returns: 转换为千克后的值（保留小数）
    public static func convertWeightToKg(value: Double, unit: String?) -> Double {
        guard let unit = unit?.lowercased() else {
            // 如果没有单位，假设已经是 kg
            return value
        }
        
        switch unit {
        case "kg", "千克", "公斤":
            return value
        case "g", "gram", "grams", "克":
            // 1 克 = 0.001 千克
            return value * 0.001
        case "lb", "lbs", "pound", "pounds", "磅":
            // 1 磅 = 0.453592 千克
            return value * 0.453592
        case "oz", "ounce", "ounces", "盎司":
            // 1 盎司（重量单位）= 0.0283495 千克
            return value * 0.0283495
        default:
            // 未知单位，假设已经是 kg
            Logger.warning("UnitConverter: Unknown weight unit '\(unit)', assuming kg")
            return value
        }
    }
}

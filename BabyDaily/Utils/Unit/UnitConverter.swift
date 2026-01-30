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
    
    // MARK: - 容量单位互转 (oz <-> ml)
    
    /// 容量单位转换（oz <-> ml）
    /// - Parameters:
    ///   - value: 原始数值
    ///   - fromUnit: 原始单位（"oz", "ml"）
    ///   - toUnit: 目标单位（"oz", "ml"）
    /// - Returns: 转换后的值
    public static func convertVolume(value: Double, fromUnit: String, toUnit: String) -> Double {
        let from = fromUnit.lowercased()
        let to = toUnit.lowercased()
        
        // 如果单位相同，直接返回
        if from == to {
            return value
        }
        
        // 先转换为毫升（作为中间单位）
        let mlValue: Double
        switch from {
        case "ml", "毫升":
            mlValue = value
        case "oz", "fl oz", "floz", "盎司":
            // 1 美制液体盎司 = 29.5735 毫升
            mlValue = value * 29.5735
        default:
            Logger.warning("UnitConverter: Unknown volume unit '\(from)', assuming ml")
            mlValue = value
        }
        
        // 从毫升转换为目标单位
        switch to {
        case "ml", "毫升":
            return mlValue
        case "oz", "fl oz", "floz", "盎司":
            // 1 毫升 = 0.033814 美制液体盎司
            return mlValue * 0.033814
        default:
            Logger.warning("UnitConverter: Unknown volume unit '\(to)', returning ml value")
            return mlValue
        }
    }
    
    // MARK: - 长度单位互转 (cm <-> in <-> ft)
    
    /// 长度单位转换（cm <-> in <-> ft）
    /// - Parameters:
    ///   - value: 原始数值
    ///   - fromUnit: 原始单位（"cm", "in", "ft"）
    ///   - toUnit: 目标单位（"cm", "in", "ft"）
    /// - Returns: 转换后的值
    public static func convertLength(value: Double, fromUnit: String, toUnit: String) -> Double {
        let from = fromUnit.lowercased()
        let to = toUnit.lowercased()
        
        // 如果单位相同，直接返回
        if from == to {
            return value
        }
        
        // 先转换为厘米（作为中间单位）
        let cmValue: Double
        switch from {
        case "cm", "厘米":
            cmValue = value
        case "in", "inch", "inches", "英寸":
            // 1 英寸 = 2.54 厘米
            cmValue = value * 2.54
        case "ft", "feet", "foot", "英尺":
            // 1 英尺 = 30.48 厘米
            cmValue = value * 30.48
        default:
            Logger.warning("UnitConverter: Unknown length unit '\(from)', assuming cm")
            cmValue = value
        }
        
        // 从厘米转换为目标单位
        switch to {
        case "cm", "厘米":
            return cmValue
        case "in", "inch", "inches", "英寸":
            // 1 厘米 = 0.393701 英寸
            return cmValue * 0.393701
        case "ft", "feet", "foot", "英尺":
            // 1 厘米 = 0.0328084 英尺
            return cmValue * 0.0328084
        default:
            Logger.warning("UnitConverter: Unknown length unit '\(to)', returning cm value")
            return cmValue
        }
    }
    
    // MARK: - 重量单位互转 (kg <-> lb <-> oz)
    
    /// 重量单位转换（kg <-> lb <-> oz）
    /// - Parameters:
    ///   - value: 原始数值
    ///   - fromUnit: 原始单位（"kg", "lb", "oz"）
    ///   - toUnit: 目标单位（"kg", "lb", "oz"）
    /// - Returns: 转换后的值
    public static func convertWeight(value: Double, fromUnit: String, toUnit: String) -> Double {
        let from = fromUnit.lowercased()
        let to = toUnit.lowercased()
        
        // 如果单位相同，直接返回
        if from == to {
            return value
        }
        
        // 先转换为千克（作为中间单位）
        let kgValue: Double
        switch from {
        case "kg", "千克", "公斤":
            kgValue = value
        case "lb", "lbs", "pound", "pounds", "磅":
            // 1 磅 = 0.453592 千克
            kgValue = value * 0.453592
        case "oz", "ounce", "ounces", "盎司":
            // 1 盎司（重量单位）= 0.0283495 千克
            kgValue = value * 0.0283495
        default:
            Logger.warning("UnitConverter: Unknown weight unit '\(from)', assuming kg")
            kgValue = value
        }
        
        // 从千克转换为目标单位
        switch to {
        case "kg", "千克", "公斤":
            return kgValue
        case "lb", "lbs", "pound", "pounds", "磅":
            // 1 千克 = 2.20462 磅
            return kgValue * 2.20462
        case "oz", "ounce", "ounces", "盎司":
            // 1 千克 = 35.274 盎司（重量单位）
            return kgValue * 35.274
        default:
            Logger.warning("UnitConverter: Unknown weight unit '\(to)', returning kg value")
            return kgValue
        }
    }
}

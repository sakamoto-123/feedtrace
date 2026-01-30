import CoreData
import SwiftUI

// 每日统计信息结构体
public struct DailyStats {
    // 喂养统计
    public var totalFeedingAmount: Double
    public var totalFeedingCount: Int
    public var formulaAmount: Double
    public var formulaCount: Int
    public var breastMilkAmount: Double
    public var breastMilkCount: Int
    public var waterAmount: Double
    public var waterCount: Int
    
    // 睡觉统计
    public var sleepCount: Int
    public var sleepDurationInHours: Double
    
    // 辅食和补剂记录列表
    public var solidFoodRecords: [Record]
    public var supplementRecords: [Record]
}

// 统计计算器类，提供公共的统计方法
public class StatsCalculator {
    /// 从已按天分组的记录中计算每日统计（适用于 RecordListContent 等已有每日 records 的场景）
    public static func getDailyStatsFromRecords(_ records: [Record]) -> DailyStats {
        computeStats(from: records)
    }

    /// 获取指定日期的每日统计数据（会先按日期过滤记录）
    public static func getDailyStats(for date: Date = Date(), from records: [Record]) -> DailyStats {
        let calendar = Calendar.current
        let dayRecords = records.filter { calendar.isDate($0.startTimestamp, inSameDayAs: date) }
        return computeStats(from: dayRecords)
    }

    /// 核心统计逻辑：从某一天的记录列表计算 DailyStats
    private static func computeStats(from dayRecords: [Record]) -> DailyStats {
        let targetVolumeUnit = UnitManager.shared.volumeUnit.rawValue

        var totalFeedingAmount = 0.0
        var totalFeedingCount = 0
        var formulaAmount = 0.0
        var formulaCount = 0
        var breastMilkAmount = 0.0
        var breastMilkCount = 0
        var waterAmount = 0.0
        var waterCount = 0

        var sleepCount = 0
        var totalSleepDurationInMinutes = 0.0

        var solidFoodRecords: [Record] = []
        var supplementRecords: [Record] = []

        func convertToTargetUnit(value: Double, fromUnit: String?) -> Double {
            guard let fromUnit = fromUnit, !fromUnit.isEmpty else { return value }
            if fromUnit.lowercased() == targetVolumeUnit.lowercased() { return value }
            return UnitConverter.convertVolume(value: value, fromUnit: fromUnit, toUnit: targetVolumeUnit)
        }

        for record in dayRecords {
            switch record.category {
            case "feeding_category":
                let originalValue = record.value
                let convertedValue = convertToTargetUnit(value: originalValue, fromUnit: record.unit)

                switch record.subCategory {
                case "nursing", "breast_bottle":
                    breastMilkAmount += convertedValue
                    breastMilkCount += 1
                    totalFeedingAmount += convertedValue
                    totalFeedingCount += 1
                case "formula":
                    formulaAmount += convertedValue
                    formulaCount += 1
                    totalFeedingAmount += convertedValue
                    totalFeedingCount += 1
                case "water_intake":
                    waterAmount += convertedValue
                    waterCount += 1
                    totalFeedingAmount += convertedValue
                    totalFeedingCount += 1
                case "solid_food":
                    solidFoodRecords.append(record)
                default:
                    break
                }
            case "activity_category":
                if record.subCategory == "sleep" {
                    sleepCount += 1
                    if let end = record.endTimestamp {
                        totalSleepDurationInMinutes += end.timeIntervalSince(record.startTimestamp) / 60
                    }
                }
            case "health_category":
                if record.subCategory == "supplement" {
                    supplementRecords.append(record)
                }
            default:
                break
            }
        }

        let sleepDurationInHours = totalSleepDurationInMinutes / 60

        return DailyStats(
            totalFeedingAmount: totalFeedingAmount,
            totalFeedingCount: totalFeedingCount,
            formulaAmount: formulaAmount,
            formulaCount: formulaCount,
            breastMilkAmount: breastMilkAmount,
            breastMilkCount: breastMilkCount,
            waterAmount: waterAmount,
            waterCount: waterCount,
            sleepCount: sleepCount,
            sleepDurationInHours: sleepDurationInHours,
            solidFoodRecords: solidFoodRecords,
            supplementRecords: supplementRecords
        )
    }
}
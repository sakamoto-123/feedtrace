import SwiftData
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
    
    // 睡觉统计
    public var sleepCount: Int
    public var sleepDurationInHours: Double
    
    // 辅食和补剂记录列表
    public var solidFoodRecords: [Record]
    public var supplementRecords: [Record]
}

// 统计计算器类，提供公共的统计方法
public class StatsCalculator {
    // 获取每日统计数据的公共静态函数
    public static func getDailyStats(for date: Date = Date(), from records: [Record]) -> DailyStats {
        let calendar = Calendar.current
        
        // 过滤出指定日期的所有记录
        let dayRecords = records.filter { calendar.isDate($0.startTimestamp, inSameDayAs: date) }
        
        // 初始化统计变量
        var totalFeedingAmount = 0.0
        var totalFeedingCount = 0
        var formulaAmount = 0.0
        var formulaCount = 0
        var breastMilkAmount = 0.0
        var breastMilkCount = 0
        
        var sleepCount = 0
        var totalSleepDurationInMinutes = 0.0
        
        var solidFoodRecords: [Record] = []
        var supplementRecords: [Record] = []
        
        // 遍历记录，计算统计数据
        for record in dayRecords {
            switch record.category {
            case "feeding_category":
                // 喂养记录处理
                let value = record.value ?? 0.0
                
                switch record.subCategory {
                case "nursing", "breast_bottle":
                    // 母乳记录
                    breastMilkAmount += value
                    breastMilkCount += 1
                    totalFeedingAmount += value
                    totalFeedingCount += 1
                case "formula":
                    // 奶粉记录
                    formulaAmount += value
                    formulaCount += 1
                    totalFeedingAmount += value
                    totalFeedingCount += 1
                case "solid_food":
                    // 辅食记录
                    solidFoodRecords.append(record)
                default:
                    break
                }
            case "activity_category":
                // 活动记录处理
                if record.subCategory == "sleep" {
                    // 睡眠记录
                    sleepCount += 1
                    if let end = record.endTimestamp {
                        let durationInMinutes = end.timeIntervalSince(record.startTimestamp) / 60
                        totalSleepDurationInMinutes += durationInMinutes
                    }
                }
            case "health_category":
                // 健康记录处理
                if record.subCategory == "supplement" {
                    // 补剂记录
                    supplementRecords.append(record)
                }
            default:
                break
            }
        }
        
        // 转换睡眠时长为小时
        let sleepDurationInHours = totalSleepDurationInMinutes / 60
        
        return DailyStats(
            totalFeedingAmount: totalFeedingAmount,
            totalFeedingCount: totalFeedingCount,
            formulaAmount: formulaAmount,
            formulaCount: formulaCount,
            breastMilkAmount: breastMilkAmount,
            breastMilkCount: breastMilkCount,
            sleepCount: sleepCount,
            sleepDurationInHours: sleepDurationInHours,
            solidFoodRecords: solidFoodRecords,
            supplementRecords: supplementRecords
        )
    }
}
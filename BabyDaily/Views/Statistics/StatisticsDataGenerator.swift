import SwiftUI

// 统计数据生成器
struct StatisticsDataGenerator {
    static func generateFeedingVolumeData(days: Int) -> [(date: Date, breastMilk: Int, formula: Int, water: Int)] {
        var data: [(date: Date, breastMilk: Int, formula: Int, water: Int)] = []
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                data.append((
                    date: date,
                    breastMilk: Int.random(in: 150...300),
                    formula: Int.random(in: 100...250),
                    water: Int.random(in: 50...150)
                ))
            }
        }
        
        return data.sorted(by: { $0.date < $1.date })
    }
    
    static func generateFeedingCountData(days: Int) -> [(date: Date, breastMilk: Int, formula: Int)] {
        var data: [(date: Date, breastMilk: Int, formula: Int)] = []
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                data.append((
                    date: date,
                    breastMilk: Int.random(in: 2...5),
                    formula: Int.random(in: 1...3)
                ))
            }
        }
        
        return data.sorted(by: { $0.date < $1.date })
    }
    
    static func generateSleepTrendData(days: Int) -> [(date: Date, duration: Double, count: Int)] {
        var data: [(date: Date, duration: Double, count: Int)] = []
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                data.append((
                    date: date,
                    duration: Double.random(in: 10.0...14.0).rounded(toPlaces: 1),
                    count: Int.random(in: 3...6)
                ))
            }
        }
        
        return data.sorted(by: { $0.date < $1.date })
    }
    
    static func generateGrowthCurveData() -> [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] {
        return [
            (month: 0, weight: 3.5, height: 50, headCircumference: 34, bmi: 14.0),
            (month: 1, weight: 5.0, height: 55, headCircumference: 38, bmi: 16.5),
            (month: 2, weight: 6.2, height: 59, headCircumference: 40, bmi: 17.9),
            (month: 3, weight: 7.1, height: 62, headCircumference: 42, bmi: 18.5),
            (month: 4, weight: 7.8, height: 65, headCircumference: 43, bmi: 18.3),
            (month: 5, weight: 8.4, height: 68, headCircumference: 44, bmi: 18.2),
            (month: 6, weight: 8.9, height: 70, headCircumference: 45, bmi: 17.9),
            (month: 7, weight: 9.3, height: 72, headCircumference: 46, bmi: 17.6),
            (month: 8, weight: 9.7, height: 74, headCircumference: 47, bmi: 17.3),
            (month: 9, weight: 10.0, height: 76, headCircumference: 48, bmi: 17.1),
            (month: 10, weight: 10.3, height: 78, headCircumference: 49, bmi: 16.9),
            (month: 11, weight: 10.6, height: 80, headCircumference: 50, bmi: 16.6)
        ]
    }
    
    static func generateDailyActivityGridData() -> [(day: Int, weekday: String, activities: [String])] {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let activities = ["喂养", "睡眠", "玩耍", "换尿布", "洗澡", "其他"]
        var data: [(day: Int, weekday: String, activities: [String])] = []
        
        for day in 1...7 {
            var dayActivities: [String] = []
            for _ in 1...24 {
                dayActivities.append(activities.randomElement()!)
            }
            let weekday = weekdays[(day + 2) % 7] // 假设今天是周三
            data.append((day: day, weekday: weekday, activities: dayActivities))
        }
        
        return data
    }
    
    static func generateDailyActivitySummaryData() -> [(activity: String, duration: Double, color: Color)] {
        return [
            (activity: "喂养", duration: 2.5, color: .red),
            (activity: "睡眠", duration: 12.0, color: .blue),
            (activity: "玩耍", duration: 3.5, color: .green),
            (activity: "换尿布", duration: 0.5, color: .yellow),
            (activity: "洗澡", duration: 0.5, color: .purple),
            (activity: "其他", duration: 5.0, color: .gray)
        ]
    }
}
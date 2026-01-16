import SwiftUI
import SwiftData
import Charts

// 导入所有子组件
import Charts

struct StatisticsView: View {
    let baby: Baby
    
    // 选项卡选择
    @State private var selectedTab: String = "feeding_trend"
    
    // 时间范围选择
    @State private var timeRange: String = "7_days"
    
    // 图表交互 - 选中的数据点
    @State private var selectedFeedingVolume: (date: Date, breastMilk: Int, formula: Int)?
    @State private var selectedFeedingCount: (date: Date, breastMilk: Int, formula: Int)?
    @State private var selectedSleepDuration: (date: Date, duration: Double)?
    @State private var selectedSleepCount: (date: Date, count: Int)?
    @State private var selectedGrowth: (month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)?
    @State private var selectedActivity: (day: Int, activity: String, hour: Int)?
    
    // 成长统计维度选择
    @State private var selectedGrowthDimension: String = "weight"
    
    // 数据生成
    private var daysCount: Int {
        switch timeRange {
        case "7_days": return 7
        case "30_days": return 30
        case "90_days": return 90
        case "12_months": return 365
        default: return 7
        }
    }
    
    private var feedingVolumeData: [(date: Date, breastMilk: Int, formula: Int)] {
        StatisticsDataGenerator.generateFeedingVolumeData(days: daysCount)
    }
    
    private var feedingCountData: [(date: Date, breastMilk: Int, formula: Int)] {
        StatisticsDataGenerator.generateFeedingCountData(days: daysCount)
    }
    
    private var sleepTrendData: [(date: Date, duration: Double, count: Int)] {
        StatisticsDataGenerator.generateSleepTrendData(days: daysCount)
    }
    
    private var growthCurveData: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] {
        StatisticsDataGenerator.generateGrowthCurveData()
    }
    
    private var dailyActivityGridData: [(day: Int, weekday: String, activities: [String])] {
        StatisticsDataGenerator.generateDailyActivityGridData()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 顶部：统计概览卡片
                OverviewCardsView()
                
                // 中间：选项卡和时间范围选择
                ChartHeaderView(selectedTab: $selectedTab, timeRange: $timeRange)
                
                // 底部：图表区域
                ScrollView {
                    VStack(spacing: 20) {
                        // 根据选项卡显示不同的图表
                        if selectedTab == "feeding_trend" {
                            FeedingTrendView(
                                volumeData: feedingVolumeData,
                                countData: feedingCountData,
                                selectedVolumeData: $selectedFeedingVolume,
                                selectedCountData: $selectedFeedingCount,
                                timeRange: timeRange
                            )
                        } else if selectedTab == "sleep_trend" {
                            SleepTrendView(
                                data: sleepTrendData,
                                selectedDuration: $selectedSleepDuration,
                                selectedCount: $selectedSleepCount,
                                timeRange: timeRange
                            )
                        } else if selectedTab == "growth_statistics" {
                            GrowthStatisticsView(
                                data: growthCurveData,
                                selectedData: $selectedGrowth,
                                selectedDimension: $selectedGrowthDimension,
                                timeRange: timeRange
                            )
                        } else if selectedTab == "daily_activity" {
                            DailyActivityView(
                                gridData: dailyActivityGridData,
                                selectedActivity: $selectedActivity,
                                timeRange: timeRange
                            )
                        }
                    }
                }
            }
            .navigationTitle("statistics".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
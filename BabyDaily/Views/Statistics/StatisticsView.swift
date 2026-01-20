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
    
    // 获取模型上下文
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // 成长统计维度选择
    @State private var selectedGrowthDimension: String = "weight"
    
    // 喂养数据缓存
    @State private var feedingDataCache: [(date: Date, breastMilk: Int, formula: Int, water: Int, breastMilkCount: Int, formulaCount: Int, waterCount: Int)]?
    // 最后一次查询的timeRange，用于判断是否需要刷新缓存
    @State private var lastTimeRange: String?
    
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
    
    private var feedingVolumeData: [(date: Date, breastMilk: Int, formula: Int, water: Int)] {
        fetchFeedingData().map { (date: $0.date, breastMilk: $0.breastMilk, formula: $0.formula, water: $0.water) }
    }
    
    private var feedingCountData: [(date: Date, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] {
        fetchFeedingData().map { (date: $0.date, breastMilkCount: $0.breastMilkCount, formulaCount: $0.formulaCount, waterCount: $0.waterCount) }
    }
    
    // 从SwiftData查询真实喂养数据（包含喂养量和次数）
    private func fetchFeedingData() -> [(date: Date, breastMilk: Int, formula: Int, water: Int, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] {
        // 检查缓存是否存在且timeRange没有变化
        if let cache = feedingDataCache, lastTimeRange == timeRange {
            return cache
        }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 计算查询开始日期：daysCount天前的00:00:00
        guard let startDate = calendar.date(byAdding: .day, value: -daysCount + 1, to: today) else {
            print("Failed to calculate start date")
            return []
        }
        
        // 计算查询结束日期：今天的23:59:59
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // 记录查询时间范围（本地时间）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        let localStartDateStr = dateFormatter.string(from: startDate)
        let localEndDateStr = dateFormatter.string(from: endDate)
        // 将外部变量提取为常量
        let babyId = baby.id
        
        // 创建查询描述符（只做一次查询）
        let fetchDescriptor: FetchDescriptor<Record> = FetchDescriptor(
            predicate: #Predicate { record in
                record.babyId == babyId &&
                record.category == "feeding_category" &&
                record.startTimestamp >= startDate &&
                record.startTimestamp <= endDate
            },
            sortBy: [SortDescriptor(\Record.startTimestamp)]
        )
        
        do {
            // 执行查询（只做一次查询）
            let records: [Record] = try modelContext.fetch(fetchDescriptor)
            
            // 按日期分组计算数据
            var groupedData: [Date: (breastMilk: Int, formula: Int, water: Int, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] = [:]
            
            // 初始化所有日期的数据
            for i in 0..<daysCount {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    let startOfDay = calendar.startOfDay(for: date)
                    groupedData[startOfDay] = (breastMilk: 0, formula: 0, water: 0, breastMilkCount: 0, formulaCount: 0, waterCount: 0)
                    // 使用本地时间格式输出日志
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone.current
                    let localDateStr = dateFormatter.string(from: startOfDay)
                    print("FeedingData: Initialized day \(i+1)/\(daysCount): \(localDateStr)")
                } else {
                    print("FeedingData: Failed to calculate date for index \(i)")
                }
            }
            
            // 计算每个记录的数据
            for record in records {
                let startOfDay = calendar.startOfDay(for: record.startTimestamp)
                let value = Int(record.value ?? 0)
                
                // 使用本地时间格式输出日志
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone.current
                let localDateStr = dateFormatter.string(from: startOfDay)
                
                // 根据子分类累加数据
                if record.subCategory == "breast_bottle" {
                    groupedData[startOfDay]?.breastMilk += value
                    groupedData[startOfDay]?.breastMilkCount += 1
                } else if record.subCategory == "formula" {
                    groupedData[startOfDay]?.formula += value
                    groupedData[startOfDay]?.formulaCount += 1
                } else if record.subCategory == "water_intake" {
                    groupedData[startOfDay]?.water += value
                    groupedData[startOfDay]?.waterCount += 1
                } else {
                    print("FeedingData: Unknown subCategory \(record.subCategory) for record ID \(record.id)")
                }
            }
            
            // 转换为数组并排序
            let result = groupedData.map { (date: $0.key, breastMilk: $0.value.breastMilk, formula: $0.value.formula, water: $0.value.water, breastMilkCount: $0.value.breastMilkCount, formulaCount: $0.value.formulaCount, waterCount: $0.value.waterCount) }
                .sorted { $0.date < $1.date }
            
            // 记录最终返回数据
            for item in result {
                // 使用本地时间格式输出日志
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone.current
                let localDateStr = dateFormatter.string(from: item.date)
            }
            
            // 更新缓存
            feedingDataCache = result
            lastTimeRange = timeRange
            
            return result
        } catch {
            print("Error fetching feeding data: \(error)")
            return []
        }
    }
    
    // 从SwiftData查询真实睡眠数据
    private func fetchSleepData() -> [(date: Date, duration: Int, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 计算查询开始日期：daysCount天前的00:00:00
        guard let startDate = calendar.date(byAdding: .day, value: -daysCount + 1, to: today) else {
            print("Failed to calculate start date")
            return []
        }
        
        // 计算查询结束日期：今天的23:59:59
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // 记录查询时间范围（本地时间）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        let localStartDateStr = dateFormatter.string(from: startDate)
        let localEndDateStr = dateFormatter.string(from: endDate)
        print("SleepData: Querying from \(localStartDateStr) to \(localEndDateStr) for baby ID: \(baby.id)")
        
        // 将外部变量提取为常量
        let babyId = baby.id
        
        // 创建查询描述符
        let fetchDescriptor: FetchDescriptor<Record> = FetchDescriptor(
            predicate: #Predicate { record in
                record.babyId == babyId && 
                record.subCategory == "sleep" &&
                record.startTimestamp >= startDate &&
                record.startTimestamp <= endDate
            },
            sortBy: [SortDescriptor(\Record.startTimestamp)]
        )
        
        do {
            // 执行查询
            let records: [Record] = try modelContext.fetch(fetchDescriptor)
            
            // 记录查询到的记录数量
            print("SleepData: Found \(records.count) sleep records")
            
            // 按日期分组计算数据
            var groupedData: [Date: (duration: Int, count: Int)] = [:]
            
            // 初始化所有日期的数据
            for i in 0..<daysCount {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    let startOfDay = calendar.startOfDay(for: date)
                    groupedData[startOfDay] = (duration: 0, count: 0)
                    // 使用本地时间格式输出日志
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone.current
                    let localDateStr = dateFormatter.string(from: startOfDay)
                    print("SleepData: Initialized day \(i+1)/\(daysCount): \(localDateStr)")
                } else {
                    print("SleepData: Failed to calculate date for index \(i)")
                }
            }
            
            // 计算每个记录的数据
            for record in records {
                let startOfDay = calendar.startOfDay(for: record.startTimestamp)
                
                // 统计睡眠次数
                groupedData[startOfDay]?.count += 1
                
                // 统计睡眠时长（只计算有endTimestamp的记录）
                if let endTimestamp = record.endTimestamp {
                    let durationInSeconds = endTimestamp.timeIntervalSince(record.startTimestamp)
                    let durationInHours = durationInSeconds / 3600
                    // 转换为整数小时
                    let durationAsInt = Int(durationInHours)
                    groupedData[startOfDay]?.duration += durationAsInt
                }
            }
            
            // 转换为数组并排序
            let result = groupedData.map { (date: $0.key, duration: $0.value.duration, count: $0.value.count) }
                .sorted { $0.date < $1.date }
            
            // 记录最终返回数据
            print("SleepData: Returning \(result.count) days of data:")
            for item in result {
                // 使用本地时间格式输出日志
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone.current
                let localDateStr = dateFormatter.string(from: item.date)
                print("SleepData: \(localDateStr): duration=\(item.duration) hours, count=\(item.count)")
            }
            
            return result
        } catch {
            print("Error fetching sleep data: \(error)")
            return []
        }
    }
    
    private var sleepTrendData: [(date: Date, duration: Int, count: Int)] {
        fetchSleepData()
    }
    
    private var growthCurveData: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] {
        StatisticsDataGenerator.generateGrowthCurveData()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 中间：选项卡和时间范围/维度选择
                ChartHeaderView(selectedTab: $selectedTab, timeRange: $timeRange, selectedDimension: $selectedGrowthDimension)
                
                // 底部：图表区域
                ScrollView {
                    VStack(spacing: 20) {
                        // 根据选项卡显示不同的图表
                        if selectedTab == "feeding_trend" {
                            FeedingTrendView(
                                volumeData: feedingVolumeData,
                                countData: feedingCountData,
                                timeRange: timeRange
                            )
                        } else if selectedTab == "sleep_trend" {
                            SleepTrendView(
                                data: sleepTrendData,
                                timeRange: timeRange
                            )
                        } else if selectedTab == "growth_statistics" {
                            GrowthStatisticsView(
                                gender: baby.gender.isEmpty ? "boy" : (baby.gender == "male" ? "boy" : "girl"),
                                dimension: selectedGrowthDimension
                            )
                        } 
                    }
                }.padding(.top, 15)
            }
            .navigationTitle("statistics".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .background(colorScheme == .light ? Color(.systemGray6) : Color.black)
            // 监听timeRange变化，清理缓存
            .onChange(of: timeRange) {
                feedingDataCache = nil
                lastTimeRange = nil
                print("FeedingData: Cleared cache due to timeRange change to \($0)")
            }
        }
    } // 结束body
} // 结束结构体

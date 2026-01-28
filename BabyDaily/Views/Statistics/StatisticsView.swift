import SwiftUI
import CoreData
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
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // 成长统计维度选择
    @State private var selectedGrowthDimension: String = "weight"
    
    // 数据状态
    @State private var feedingData: [(date: Date, breastMilk: Int, formula: Int, water: Int, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] = []
    @State private var sleepData: [(date: Date, duration: Int, count: Int)] = []
    @State private var growthData: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] = []
    
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
        feedingData.map { (date: $0.date, breastMilk: $0.breastMilk, formula: $0.formula, water: $0.water) }
    }
    
    private var feedingCountData: [(date: Date, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] {
        feedingData.map { (date: $0.date, breastMilkCount: $0.breastMilkCount, formulaCount: $0.formulaCount, waterCount: $0.waterCount) }
    }
    
    // 从CoreData查询真实喂养数据（包含喂养量和次数）
    private func loadFeedingData() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 计算查询开始日期：daysCount天前的00:00:00
        guard let startDate = calendar.date(byAdding: .day, value: -daysCount + 1, to: today) else {
            Logger.error("Failed to calculate start date")
            feedingData = []
            return
        }
        
        // 计算查询结束日期：今天的23:59:59
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // 记录查询时间范围（本地时间）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        // let localStartDateStr = dateFormatter.string(from: startDate)
        // let localEndDateStr = dateFormatter.string(from: endDate)
        // 将外部变量提取为常量
        let babyId = baby.id
        
        // 创建查询请求
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.predicate = NSPredicate(format: "baby.id == %@ AND category == %@ AND startTimestamp >= %@ AND startTimestamp <= %@",
                                      babyId as CVarArg, "feeding_category", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Record.startTimestamp, ascending: true)]
        
        do {
            // 执行查询（只做一次查询）
            let records = try viewContext.fetch(request)
            
            // 按日期分组计算数据
            var groupedData: [Date: (breastMilk: Int, formula: Int, water: Int, breastMilkCount: Int, formulaCount: Int, waterCount: Int)] = [:]
            
            // 初始化所有日期的数据
            for i in 0..<daysCount {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    let startOfDay = calendar.startOfDay(for: date)
                    groupedData[startOfDay] = (breastMilk: 0, formula: 0, water: 0, breastMilkCount: 0, formulaCount: 0, waterCount: 0)
                    // 使用本地时间格式输出日志
                    // let dateFormatter = DateFormatter()
                    // dateFormatter.dateFormat = "yyyy-MM-dd"
                    // dateFormatter.timeZone = TimeZone.current
                    // let localDateStr = dateFormatter.string(from: startOfDay)
                } else {
                    Logger.warning("FeedingData: Failed to calculate date for index \(i)")
                }
            }
            
            // 计算每个记录的数据
            for record in records {
                let startOfDay = calendar.startOfDay(for: record.startTimestamp)
                // 将容量单位转换为 ml
                let valueInMl = UnitConverter.convertVolumeToMl(value: record.value, unit: record.unit)
                
                // 使用本地时间格式输出日志
                // let dateFormatter = DateFormatter()
                // dateFormatter.dateFormat = "yyyy-MM-dd"
                // dateFormatter.timeZone = TimeZone.current
                // let localDateStr = dateFormatter.string(from: startOfDay)
                
                // 根据子分类累加数据
                if record.subCategory == "breast_bottle" {
                    groupedData[startOfDay]?.breastMilk += Int(valueInMl)
                    groupedData[startOfDay]?.breastMilkCount += 1
                } else if record.subCategory == "formula" {
                    groupedData[startOfDay]?.formula += Int(valueInMl)
                    groupedData[startOfDay]?.formulaCount += 1
                } else if record.subCategory == "water_intake" {
                    groupedData[startOfDay]?.water += Int(valueInMl)
                    groupedData[startOfDay]?.waterCount += 1
                }
            }
            
            // 转换为数组并排序
            let result = groupedData.map { (date: $0.key, breastMilk: $0.value.breastMilk, formula: $0.value.formula, water: $0.value.water, breastMilkCount: $0.value.breastMilkCount, formulaCount: $0.value.formulaCount, waterCount: $0.value.waterCount) }
                .sorted { $0.date < $1.date }
            
            // 记录最终返回数据
            // for item in result {
            //     // 使用本地时间格式输出日志
            //     let dateFormatter = DateFormatter()
            //     dateFormatter.dateFormat = "yyyy-MM-dd"
            //     dateFormatter.timeZone = TimeZone.current
            //     let localDateStr = dateFormatter.string(from: item.date)
            // }
            
            // 更新数据
            feedingData = result
        } catch {
            Logger.error("Error fetching feeding data: \(error)")
            feedingData = []
        }
    }
    
    // 从CoreData查询真实睡眠数据
    private func loadSleepData() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 计算查询开始日期：daysCount天前的00:00:00
        guard let startDate = calendar.date(byAdding: .day, value: -daysCount + 1, to: today) else {
            Logger.error("Failed to calculate start date")
            sleepData = []
            return
        }
        
        // 计算查询结束日期：今天的23:59:59
        let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // 记录查询时间范围（本地时间）
        // let dateFormatter = DateFormatter()
        // dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // dateFormatter.timeZone = TimeZone.current
        // let localStartDateStr = dateFormatter.string(from: startDate)
        // let localEndDateStr = dateFormatter.string(from: endDate)
        // Logger.debug("SleepData: Querying from \(localStartDateStr) to \(localEndDateStr) for baby ID: \(baby.id)")
        
        // 将外部变量提取为常量
        let babyId = baby.id
        
        // 创建查询请求
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.predicate = NSPredicate(format: "baby.id == %@ AND subCategory == %@ AND startTimestamp >= %@ AND startTimestamp <= %@",
                                      babyId as CVarArg, "sleep", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Record.startTimestamp, ascending: true)]
        
        do {
            // 执行查询
            let records = try viewContext.fetch(request)
            
            // 记录查询到的记录数量
            Logger.debug("SleepData: Found \(records.count) sleep records")
            
            // 按日期分组计算数据
            var groupedData: [Date: (duration: Int, count: Int)] = [:]
            
            // 初始化所有日期的数据
            for i in 0..<daysCount {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    let startOfDay = calendar.startOfDay(for: date)
                    groupedData[startOfDay] = (duration: 0, count: 0)
                    // 使用本地时间格式输出日志
                    // let dateFormatter = DateFormatter()
                    // dateFormatter.dateFormat = "yyyy-MM-dd"
                    // dateFormatter.timeZone = TimeZone.current
                    // let localDateStr = dateFormatter.string(from: startOfDay)
                    // Logger.debug("SleepData: Initialized day \(i+1)/\(daysCount): \(localDateStr)")
                } else {
                    Logger.warning("SleepData: Failed to calculate date for index \(i)")
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
            Logger.debug("SleepData: Returning \(result.count) days of data:")
            // for item in result {
            //     // 使用本地时间格式输出日志
            //     let dateFormatter = DateFormatter()
            //     dateFormatter.dateFormat = "yyyy-MM-dd"
            //     dateFormatter.timeZone = TimeZone.current
            //     let localDateStr = dateFormatter.string(from: item.date)
            //     Logger.debug("SleepData: \(localDateStr): duration=\(item.duration) hours, count=\(item.count)")
            // }
            
            sleepData = result
        } catch {
            Logger.error("Error fetching sleep data: \(error)")
            sleepData = []
        }
    }
    
    private var sleepTrendData: [(date: Date, duration: Int, count: Int)] {
        sleepData
    }
    
    private var growthCurveData: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] {
        growthData
    }
    
    // 加载数据的方法
    private func loadData() {
        if selectedTab == "feeding_trend" {
            loadFeedingData()
        } else if selectedTab == "sleep_trend" {
            loadSleepData()
        } else if selectedTab == "growth_statistics" {
            loadGrowthData()
        }
    }
    
    // 从CoreData查询真实成长曲线数据
    private func loadGrowthData() {
        let calendar = Calendar.current
        let babyId = baby.id
        let birthday = baby.birthday
        let birthStartOfDay = calendar.startOfDay(for: birthday)
        
        // 创建查询请求：获取所有 growth_category 的记录
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.predicate = NSPredicate(format: "baby.id == %@ AND category == %@", babyId as CVarArg, "growth_category")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Record.startTimestamp, ascending: true)]
        
        do {
            // 执行查询
            let records = try viewContext.fetch(request)
            
            // 计算从出生到现在有多少个30天周期（最多24个月，即720天）
            let now = Date()
            let daysSinceBirth = calendar.dateComponents([.day], from: birthStartOfDay, to: now).day ?? 0
            let maxMonths = max(1, min(24, (daysSinceBirth / 30) + 1)) // 至少1个月，最多24个月
            
            // 使用字典存储每个周期的最新数据，键为月份索引
            // 值包含该周期内最新的体重、身高、头围及其时间戳
            struct PeriodLatest {
                var weight: (value: Double, timestamp: Date)?
                var height: (value: Double, timestamp: Date)?
                var head: (value: Double, timestamp: Date)?
            }
            var periodData: [Int: PeriodLatest] = [:]
            
            // 只遍历一次记录，根据日期计算属于哪个周期
            for record in records {
                let value = record.value
                
                // 计算记录属于哪个周期（30天周期）
                let recordDate = calendar.startOfDay(for: record.startTimestamp)
                guard recordDate >= birthStartOfDay else { continue } // 忽略出生前的记录
                
                let daysFromBirth = calendar.dateComponents([.day], from: birthStartOfDay, to: recordDate).day ?? 0
                let month = daysFromBirth / 30
                
                // 只处理有效范围内的周期
                guard month >= 0 && month < maxMonths else { continue }
                
                // 获取或创建该周期的数据
                var period = periodData[month] ?? PeriodLatest()
                
                // 根据记录类型更新对应周期的最新数据
                switch record.subCategory {
                case "weight":
                    // 转换为 kg
                    let weightInKg = UnitConverter.convertWeight(value: value, fromUnit: record.unit ?? "kg", toUnit: "kg")
                    if period.weight == nil || record.startTimestamp > period.weight!.timestamp {
                        period.weight = (value: weightInKg, timestamp: record.startTimestamp)
                    }
                case "height":
                    // 转换为 cm
                    let heightInCm = UnitConverter.convertLength(value: value, fromUnit: record.unit ?? "cm", toUnit: "cm")
                    if period.height == nil || record.startTimestamp > period.height!.timestamp {
                        period.height = (value: heightInCm, timestamp: record.startTimestamp)
                    }
                case "head":
                    // 转换为 cm
                    let headInCm = UnitConverter.convertLength(value: value, fromUnit: record.unit ?? "cm", toUnit: "cm")
                    if period.head == nil || record.startTimestamp > period.head!.timestamp {
                        period.head = (value: headInCm, timestamp: record.startTimestamp)
                    }
                default:
                    break
                }
                
                // 保存更新后的周期数据
                periodData[month] = period
            }
            
            // 构建结果数组，使用前一个周期的值填充缺失的数据
            var result: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)] = []
            
            // 初始化前一个月的数据（使用 Baby 模型中的初始值，已转换为标准单位）
            var lastWeight = baby.weight // 已经是 kg
            var lastHeight = baby.height // 已经是 cm
            var lastHeadCircumference = baby.headCircumference // 已经是 cm
            
            // 按月份顺序生成结果
            for month in 0..<maxMonths {
                // 如果这个周期有数据，更新最新值；否则沿用前一个周期的值
                if let period = periodData[month] {
                    if let weight = period.weight {
                        lastWeight = weight.value
                    }
                    if let height = period.height {
                        lastHeight = height.value
                    }
                    if let head = period.head {
                        lastHeadCircumference = head.value
                    }
                }
                // 如果没有该周期的数据，lastWeight、lastHeight、lastHeadCircumference 保持前一个周期的值
                
                // 计算 BMI：BMI = weight(kg) / (height(m))^2
                let heightInMeters = lastHeight / 100.0
                let bmi = lastHeight > 0 ? lastWeight / (heightInMeters * heightInMeters) : 0.0
                
                // 添加到结果中
                result.append((
                    month: month,
                    weight: lastWeight,
                    height: lastHeight,
                    headCircumference: lastHeadCircumference,
                    bmi: bmi
                ))
            }
            
            growthData = result
        } catch {
            Logger.error("Error fetching growth curve data: \(error)")
            // 如果查询失败，返回空数组或使用默认数据
            growthData = []
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 中间：选项卡和时间范围/维度选择
                ChartHeaderView(selectedTab: $selectedTab, timeRange: $timeRange, selectedDimension: $selectedGrowthDimension)
                
                // 底部：图表区域
                ScrollView {
                    HStack{}.frame(height: 5)
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
                                dimension: selectedGrowthDimension,
                                growthCurveData: growthCurveData
                            )
                        } 
                    }
                }
            }
            .navigationTitle("statistics".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.themeListBackground(for: colorScheme))
            // 监听变化，更新数据
            .onAppear {
                loadData()
            }
            .onChange(of: selectedTab) { _, _ in
                loadData()
            }
            .onChange(of: timeRange) { _, _ in
                loadData()
            }
            .onChange(of: selectedGrowthDimension) { _, _ in
                loadData()
            }
        }
    } // 结束body
} // 结束结构体

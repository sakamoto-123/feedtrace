import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [Record]
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var unitManager = UnitManager.shared
    @State private var showingBabySwitcher = false
    @State private var showingBabyCreation = false
    
    init(baby: Binding<Baby>) {
        self._baby = baby
        let babyId = baby.wrappedValue.id
        _records = Query(filter: #Predicate { $0.babyId == babyId }, sort: [SortDescriptor(\Record.startTimestamp, order: .reverse)])
    }
    
    /// 仍在进行的记录（仅保留未结束且为指定子类的记录）
    private var ongoingRecords: [Record] {
        // 需要展示的子类白名单
        let ongoingSubCategories: Set<String> = ["nursing", "pumping", "sleep"]
        
        return records.filter { record in
            record.endTimestamp == nil && ongoingSubCategories.contains(record.subCategory)
        }
    }
    
    // 今天的统计数据
    private var todayStats: DailyStats {
        return StatsCalculator.getDailyStats(from: records)
    }
    
    // 快速操作列表（根据原型：母乳、瓶喂、睡眠、纸尿裤、辅食、笔记、体重、身高）
    private var quickActions: [(icon: String, category: String, name: String, color: Color)] {
        // 定义快速操作对应的本地化键
        let quickActionKeys = [
            "nursing",
            "formula", 
            "sleep", 
            "diaper", 
            "solid_food", 
            "weight",
            "height"
        ]
        
        return Constants.allCategorys.reduce(into: [(icon: String, category: String, name: String, color: Color)]()) { result, categoryEntry in
            let category = categoryEntry.key
            let actions = categoryEntry.value
            
            // 过滤出匹配的快速操作，并添加category字段
            let matchingActions = actions.filter { quickActionKeys.contains($0.name) }
            for action in matchingActions {
                result.append((
                    icon: action.icon,
                    category: category,
                    name: action.name,
                    color: action.color
                ))
            }
        }
    }
    
    // 所有操作分类 - 保持原始顺序
    private var allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])] {
        return Constants.allCategorysByOrder
    }
    
    // 最新生长数据
    private var latestGrowthData: GrowthData {
        baby.getLatestGrowthData(from: records)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定在顶部的宝宝基本信息模块
                BabyInfoHeader(baby: baby, latestGrowthData: latestGrowthData, showingBabySwitcher: $showingBabySwitcher)
                
                // 可滚动的内容区域
                ScrollView {
                    VStack(spacing: 4) {
                        // 模块1：进行中区域
                        if !ongoingRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(ongoingRecords, id: \.id) { record in
                                    OngoingRecordCard(record: record)
                                }
                            }
                            .padding(.top, 16)
                        }

                        // 今天的记录统计
                        TodayStatistics(todayStats: todayStats, unitManager: unitManager)
                        
                        // 快速操作区域
                        // QuickActionsSection(quickActions: quickActions, baby: baby)

                         // 所有操作区域
                        AllActionsSection(allActions: allActions, baby: baby)

                        HStack{ Spacer() }.frame(height: 20)
                    }
                }
            }
            .background(Color.themeListBackground(for: colorScheme))
            .toolbar(.hidden, for: .navigationBar)
            // 宝宝切换视图
            .sheet(isPresented: $showingBabySwitcher) {
                BabySwitcherView(
                    currentBaby: baby,
                    onSelectBaby: { selectedBaby in
                        self.baby = selectedBaby
                    },
                    onAddBaby: {
                        showingBabyCreation = true
                    }
                )
            }
            // 新增宝宝视图
            .sheet(isPresented: $showingBabyCreation) {
                BabyCreationView(isEditing: false, isFirstCreation: false)
            }
        }
    }
}

// 宝宝信息头部组件
struct BabyInfoHeader: View {
    let baby: Baby
    let latestGrowthData: GrowthData
    @Binding var showingBabySwitcher: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirm = false
    @Query private var records: [Record]
    @Query private var allBabies: [Baby]
    
    // 判断是否有多个宝宝
    private var hasMultipleBabies: Bool {
        allBabies.count > 1
    }
    
    init(baby: Baby, latestGrowthData: GrowthData, showingBabySwitcher: Binding<Bool>) {
        self.baby = baby
        self.latestGrowthData = latestGrowthData
        self._showingBabySwitcher = showingBabySwitcher
        let babyId = baby.id
        _records = Query(filter: #Predicate { $0.babyId == babyId })
        _allBabies = Query(sort: [SortDescriptor(\Baby.createdAt)])
    }
    
    #if DEBUG
    // 删除当前宝宝的所有记录 - 仅在debug模式下可用
    private func deleteAllRecords() {
        // 删除所有记录
        for record in records {
            modelContext.delete(record)
        }
        
        // 删除所有UserSetting数据
        do {
            let fetchDescriptor = FetchDescriptor<UserSetting>()
            let userSettings = try modelContext.fetch(fetchDescriptor)
            for setting in userSettings {
                modelContext.delete(setting)
            }
        } catch {
            Logger.error("Failed to fetch UserSetting: \(error)")
        }
        
        do {
            try modelContext.save()
            Logger.debug("Successfully deleted all records for baby: \(baby.name)")
            Logger.debug("Successfully deleted all UserSetting data")
        } catch {
            Logger.error("Failed to delete all records: \(error)")
        }
    }
    #endif
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 宝宝头像和名称区域
            HStack(alignment: .center, spacing: 12) {
                // 宝宝头像
                if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height:44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray)
                }
                
                // 宝宝名称和年龄
                VStack(alignment: .leading, spacing: 4) {
                    Text(baby.name)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(calculateBabyAge(baby))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // 只在有多个宝宝时显示切换按钮
                if hasMultipleBabies {
                    Button(action: {
                        showingBabySwitcher = true
                    }) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .padding(.leading, -4)
                    }
                }
                
                Spacer()
                
                // 一键删除所有记录按钮 - 仅在debug模式下显示
                #if DEBUG
                Button(action: {
                    showingDeleteConfirm = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .confirmationDialog("delete_all_records_confirm".localized, isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                    Button("delete".localized, role: .destructive) {
                        deleteAllRecords()
                    }
                    Button("cancel".localized, role: .cancel) {}
                } message: {
                    Text("delete_all_records_message".localized)
                }
                #endif
            }
            .padding(.leading, 20)
            .padding(.bottom, 12)
            
            // 体重、身高和头围信息（横向排列，固定在顶部）
            VStack(alignment: .center, spacing: 6) {
                // 体重
                HStack(spacing: 8) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                    Text(String(format: "%.1f", latestGrowthData.weight))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("kg".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // 身高
                HStack(spacing: 8) {
                    Image(systemName: "ruler")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    Text(latestGrowthData.height > 0 ? String(format: "%.0f", latestGrowthData.height) : "---")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("cm".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // 头围
                // HStack(spacing: 8) {
                //     Image(systemName: "circle.dashed")
                //         .font(.system(size: 14))
                //         .foregroundColor(Color(red: 0.6, green: 0.2, blue: 1.0))
                //     Text(latestGrowthData.headCircumference > 0 ? String(format: "%.0f", latestGrowthData.headCircumference) : "---")
                //         .font(.system(size: 14, weight: .medium))
                //         .foregroundColor(.secondary)
                //     Text("cm".localized)
                //         .font(.system(size: 14))
                //         .foregroundColor(.secondary)
                // }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .background(Color.themeCardBackground(for: colorScheme))
    }
}

// 进行中记录卡片组件
struct OngoingRecordCard: View {
    let record: Record
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    // 计时器相关状态
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isNavigatingToDetail = false
    
    // 计算已过时间并格式化
    private var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        
        let days = totalSeconds / (24 * 3600)
        let hours = (totalSeconds % (24 * 3600)) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if days > 0 {
            if hours > 0 {
                return String(format: "elapsed_time_days_hours".localized, days, hours)
            } else {
                return String(format: "elapsed_time_days".localized, days)
            }
        } else if hours > 0 {
            if minutes > 0 {
                return String(format: "elapsed_time_hours_minutes".localized, hours, minutes)
            } else {
                return String(format: "elapsed_time_hours".localized, hours)
            }
        } else if minutes > 0 {
            if seconds > 0 {
                return String(format: "elapsed_time_minutes_seconds".localized, minutes, seconds)
            } else {
                return String(format: "elapsed_time_minutes".localized, minutes)
            }
        } else {
            return String(format: "elapsed_time_seconds".localized, seconds)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧可点击区域
            HStack(spacing: 12) {
                Text(record.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center) {
                        Text("\(record.subCategory.localized)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(String(format: "started_at".localized, record.startTimestamp.formatted(Date.FormatStyle(time: .shortened))))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 计时器显示
                    Text(formattedElapsedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isNavigatingToDetail = true
            }
            
            Spacer()
            
            // 右侧按钮区域
            Button("ending".localized) {
                // 结束记录
                record.endTimestamp = Date()
                do {
                try modelContext.save()
            } catch {
                Logger.error("Failed to save record: \(error)")
            }
            }
            .font(.system(size: 14))
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .navigationDestination(isPresented: $isNavigatingToDetail) {
            RecordDetailView(record: record)
        }
        .onAppear {
            // 初始化已过时间
            elapsedTime = Date().timeIntervalSince(record.startTimestamp)
            
            // 启动定时器，每秒更新一次
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                _ in
                elapsedTime = Date().timeIntervalSince(record.startTimestamp)
            }
        }
        .onDisappear {
            // 停止定时器
            timer?.invalidate()
            timer = nil
        }
    }
}

// 今日统计信息组件
struct TodayStatistics: View {
    let todayStats: DailyStats
    let unitManager: UnitManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today_statistics".localized)
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], alignment: .leading, spacing: 24) {
                
                // 喂养信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("feeding".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("formula".localized + "colon_separator".localized + "\(todayStats.formulaAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("breast_milk".localized + "colon_separator".localized + "\(todayStats.breastMilkAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                        .font(.system(size: 14, weight: .medium))       
                        .foregroundColor(.secondary)
                }

                // 睡眠信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("sleep".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("duration_label".localized + "colon_separator".localized + "\(todayStats.sleepDurationInHours.smartDecimal) " + "hour_unit".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("count_label".localized + "colon_separator".localized + "\(todayStats.sleepCount) " + "times".localized)
                        .font(.system(size: 14, weight: .medium))       
                        .foregroundColor(.secondary)
                }

                // 补剂信息
               if !todayStats.supplementRecords.isEmpty {
                   VStack(alignment: .leading, spacing: 8) {
                        Text("supplement".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(todayStats.supplementRecords, id: \.self) { record in
                            let valueText = record.value != nil ? " \(record.value!.smartDecimal) \(record.unit ?? "")" : ""
                            Text("\(record.name!)\(valueText)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }   
                    }
               }

                // 辅食信息
               if !todayStats.solidFoodRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("solid_food".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                        ForEach(todayStats.solidFoodRecords, id: \.self) { record in
                            let valueText = record.value != nil ? " \(record.value!.smartDecimal) \(record.unit ?? "")" : ""
                            Text("\(record.name!)\(valueText)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        } 
                    }
               }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// 快速操作区域组件
struct QuickActionsSection: View {
    let quickActions: [(icon: String, category: String, name: String, color: Color)]
    let baby: Baby
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("quick_actions".localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 自适应四列网格布局
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 20) {
                ForEach(quickActions, id: \.name) { action in
                    CategoryActionButton(
                        icon: action.icon,
                        name: action.name,
                        color: action.color,
                        category: action.category,
                        baby: baby,
                    )
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// 所有操作区域组件
struct AllActionsSection: View {
    let allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])]
    let baby: Baby
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("all_actions".localized)
                .font(.headline)
            
            ForEach(Array(allActions.enumerated()), id: \.element.category) { index, categoryItem in
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoryItem.category.localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: 12)], spacing: 20) {
                        ForEach(categoryItem.actions, id: \.name) { action in
                            CategoryActionButton(
                                icon: action.icon,
                                name: action.name,
                                color: action.color,
                                category: categoryItem.category,
                                baby: baby
                            )
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }

                     if index != allActions.count - 1 {   // 最后一项不要 Divider
                        Divider()
                            .background(Color(.systemGray6))
                            .padding(.vertical, 8)
                    }                        
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// 快速操作按钮组件
struct CategoryActionButton: View {
    let icon: String
    let name: String
    let color: Color
    let category: String
    let baby: Baby
    let size: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            NavigationLink(destination: RecordEditView(baby: baby, recordType: (category: category, subCategory: name, icon: icon))) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.5))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 2)
                        )
                    
                    Text(icon)
                        .font(.system(size: 32))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(name.localized)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

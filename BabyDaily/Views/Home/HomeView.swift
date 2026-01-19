import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [Record]

    @StateObject private var unitManager = UnitManager.shared
    
    init(baby: Baby) {
        self.baby = baby
        let babyId = baby.id
        _records = Query(filter: #Predicate { $0.babyId == babyId }, sort: [SortDescriptor(\Record.startTimestamp, order: .reverse)])
    }
    

    
    // 进行中记录（仅显示吸奶或亲喂）
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
                BabyInfoHeader(baby: baby, latestGrowthData: latestGrowthData)
                
                Divider()
                
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
                    }
                }.padding(.bottom, 20)
            }
            .background(Color(.systemGray6))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// 宝宝信息头部组件
struct BabyInfoHeader: View {
    let baby: Baby
    let latestGrowthData: GrowthData
    
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
                
                Spacer()
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
        .background(.background)
    }
}

// 进行中记录卡片组件
struct OngoingRecordCard: View {
    let record: Record
    
    var body: some View {
        HStack(spacing: 12) {
            Text(record.icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.subCategory.localized) · 进行中")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(String(format: "started_at".localized, record.startTimestamp.formatted(Date.FormatStyle(time: .shortened))))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("ending".localized) {
                // 结束记录
            }
            .font(.system(size: 14))
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// 今日统计信息组件
struct TodayStatistics: View {
    let todayStats: DailyStats
    let unitManager: UnitManager
    
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
                    
                    Text("formula".localized + ": \(todayStats.formulaAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                    Text("breast_milk".localized + ": \(todayStats.breastMilkAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                        .font(.system(size: 14, weight: .medium))       
                }

                // 睡眠信息
                VStack(alignment: .leading, spacing: 8) {
                    Text("sleep".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("时长".localized + ": \(todayStats.sleepDurationInHours.smartDecimal) 小时")
                        .font(.system(size: 14, weight: .medium))
                    Text("次数".localized + ": \(todayStats.sleepCount) 次")
                        .font(.system(size: 14, weight: .medium))       
                }

                // 补剂信息
               if !todayStats.supplementRecords.isEmpty {
                    Text("supplement".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(todayStats.supplementRecords, id: \.self) { record in
                        let valueText = record.value != nil ? " \(record.value!.smartDecimal) \(record.unit ?? "")" : ""
                        Text("\(record.name)\(valueText)")
                            .font(.system(size: 14, weight: .medium))
                    }
               }

                // 辅食信息
               if !todayStats.solidFoodRecords.isEmpty {
                    Text("solid_food".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(todayStats.solidFoodRecords, id: \.self) { record in
                        let valueText = record.value != nil ? " \(record.value!.smartDecimal) \(record.unit ?? "")" : ""
                        Text("\(record.name)\(valueText)")
                            .font(.system(size: 14, weight: .medium))
                    }
               }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// 快速操作区域组件
struct QuickActionsSection: View {
    let quickActions: [(icon: String, category: String, name: String, color: Color)]
    let baby: Baby
    
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
        .background(.background)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// 所有操作区域组件
struct AllActionsSection: View {
    let allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])]
    let baby: Baby
    
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
                        }
                    }

                     if index != allActions.count - 1 {   // 最后一项不要 Divider
                        Divider()
                            .background(Color(.systemGray4))
                            .padding(.vertical, 8)
                    }                        
                }
            }
        }
        .padding()
        // .background(.background)
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
        VStack(spacing: 8) {
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
        }
        .frame(maxWidth: .infinity)
    }
}

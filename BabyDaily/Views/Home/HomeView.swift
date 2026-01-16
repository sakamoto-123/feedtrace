import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [Record] // 这里需要过滤当前宝宝的记录
    
    // 计算宝宝年龄
    private var babyAge: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: baby.birthday, to: now)
        
        if let years = components.year, years > 0 {
            if let months = components.month, months > 0 {
                return "\(years)\("year".localized)\(months)\("month".localized)"
            } else {
                return "\(years)\("year".localized)"
            }
        } else if let months = components.month, months > 0 {
            if let days = components.day, days > 0 {
                return "\(months)\("month".localized)\(days)\("day".localized)"
            } else {
                return "\(months)\("month".localized)"
            }
        } else if let days = components.day {
            return "\(days)\("day".localized)"
        } else {
            return "0\("day".localized)"
        }
    }
    
    // 模拟今天的统计数据
    private var todayStats: (feeding: [String: Int], activity: [String: Int]) {
        // 这里应该从records中过滤今天的记录并计算统计数据
        return (
            feeding: ["breast_milk".localized: 200, "formula_milk_stat".localized: 150, "complementary_food_stat".localized: 50, "supplement_stat".localized: 10],
            activity: ["stool".localized: 2, "urine".localized: 5, "sleep_duration".localized: 12, "sleep_count".localized: 3]
        )
    }
    
    // 模拟进行中记录
    @State private var ongoingRecords: [Record] = []
    
    // 快速操作列表
    private var quickActions: [(icon: String, name: String)] {
        return [
            (icon: "🤱", name: "direct_feeding".localized),
            (icon: "🍼", name: "formula_milk".localized),
            (icon: "🥣", name: "solid_food".localized),
            (icon: "💧", name: "water".localized),
            (icon: "😴", name: "sleep".localized),
            (icon: "🧻", name: "diaper".localized),
            (icon: "🛁", name: "bath".localized),
            (icon: "📏", name: "measure_height".localized)
        ]
    }
    
    // 所有操作分类
    private var allActions: [String: [(icon: String, name: String)]] {
        return [
            "feeding_category".localized: [(icon: "🤱", name: "breastfeeding".localized), (icon: "🍼", name: "formula".localized), (icon: "🥣", name: "complementary_food".localized), (icon: "💧", name: "water_intake".localized)],
            "activity_category".localized: [(icon: "😴", name: "sleep_activity".localized), (icon: "🧻", name: "diaper_change".localized), (icon: "🛁", name: "bath_activity".localized), (icon: "🚶", name: "walking".localized), (icon: "🧸", name: "playing".localized), (icon: "🥛", name: "pumping".localized)],
            "growth_category".localized: [(icon: "📏", name: "measure_height_action".localized), (icon: "⚖️", name: "measure_weight".localized), (icon: "📐", name: "measure_head".localized)],
            "health_category".localized: [(icon: "🟡", name: "jaundice".localized), (icon: "🏥", name: "medical_visit".localized), (icon: "💉", name: "vaccination".localized), (icon: "🌡️", name: "temperature".localized), (icon: "💊", name: "medication".localized), (icon: "🦴", name: "supplement".localized)],
            "milestone_category".localized: [(icon: "🦷", name: "first_tooth".localized), (icon: "🪑", name: "first_sit".localized), (icon: "🐢", name: "first_crawl".localized), (icon: "🔄", name: "first_roll".localized), (icon: "🗣️", name: "first_word".localized)]
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 模块1：宝宝基本信息
                    HStack(alignment: .center, spacing: 12) {
                        // 宝宝头像
                        if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                        }
                        
                        // 宝宝名称和年龄
                        VStack(alignment: .leading, spacing: 4) {
                            Text(baby.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(babyAge)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 宝宝体重、身高、头围
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\("weight".localized): \(baby.weight)\("kg".localized)")
                            .font(.subheadline)
                        Text("\("height".localized): \(baby.height)\("cm".localized)")
                            .font(.subheadline)
                        Text("\("head_circumference".localized): \(baby.headCircumference)\("cm".localized)")
                            .font(.subheadline)
                    }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 模块2：今天的记录统计
                    VStack(alignment: .leading, spacing: 12) {
                        Text("today_statistics".localized)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // 喂养信息
                        VStack(alignment: .leading, spacing: 8) {
                            Text("feeding".localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 16) {
                                ForEach(todayStats.feeding.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    Text("\(key): \(value)ml")
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 活动信息
                        VStack(alignment: .leading, spacing: 8) {
                            Text("activity".localized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 16) {
                                ForEach(todayStats.activity.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    Text("\(key): \(value)\(key.contains("时长") ? "小时" : "次")")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 模块3：进行中区域
                    if !ongoingRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ongoing".localized)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(ongoingRecords, id: \.id) { record in
                                // 进行中记录卡片
                                HStack(spacing: 12) {
                                    Text(record.icon)
                                        .font(.title)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(record.subCategory)中")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("started_at".localized + " " + record.startTimestamp.formatted(Date.FormatStyle(time: .shortened)))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("ending".localized) {
                                    // 结束记录
                                }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 模块4：快速操作区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                        Text("quick_actions".localized)
                            .font(.headline)
                        Spacer()
                        Button("edit".localized) {
                            // 编辑快速操作
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(quickActions, id: \.name) { action in
                                    VStack(spacing: 8) {
                                        NavigationLink(destination: RecordEditView(baby: baby, recordType: (category: "喂养", subCategory: action.name, icon: action.icon))) {
                                            Text(action.icon)
                                                .font(.title)
                                                .frame(width: 60, height: 60)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(12)
                                        }
                                        Text(action.name)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 模块5：所有操作的区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("all_actions".localized)
                        .font(.headline)
                        .padding(.horizontal)
                        
                        ForEach(allActions.sorted(by: { $0.key < $1.key }), id: \.key) { category, actions in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(actions, id: \.name) { action in
                                        NavigationLink(destination: RecordEditView(baby: baby, recordType: (category: category, subCategory: action.name, icon: action.icon))) {
                                            VStack(spacing: 4) {
                                                Text(action.icon)
                                                    .font(.title2)
                                                Text(action.name)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("baby_diary".localized)
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 切换宝宝
                    }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
}
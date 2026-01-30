import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var baby: Baby
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var records: FetchedResults<Record>
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var unitManager = UnitManager.shared
    @State private var showingBabySwitcher = false
    @State private var showingBabyCreation = false
    
    init(baby: Binding<Baby>) {
        self._baby = baby
        let babyId = baby.wrappedValue.id
        // Core Data Fetch Request
        _records = FetchRequest<Record>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Record.startTimestamp, ascending: false)],
            predicate: NSPredicate(format: "baby.id == %@", babyId as CVarArg),
            animation: .default)
    }
    
    /// 仍在进行的记录（仅保留未结束且为指定子类的记录）
    private var ongoingRecords: [Record] {
        // 需要展示的子类白名单
        let ongoingSubCategories: Set<String> = ["nursing", "pumping", "sleep"]
        
        return records.filter { record in
            record.endTimestamp == nil && ongoingSubCategories.contains(record.subCategory ?? "")
        }
    }
    
    // 今天的统计数据
    private var todayStats: DailyStats {
        return StatsCalculator.getDailyStats(from: Array(records))
    }
    
    // 所有操作分类 - 保持原始顺序
    private var allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])] {
        return Constants.allCategorysByOrder
    }
    
    // 最新生长数据
    private var latestGrowthData: GrowthData {
        baby.getLatestGrowthData(from: Array(records))
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
                                    OngoingRecordCard(recordId: record.id)
                                }
                            }
                            .padding(.top, 16)
                        }

                        // 今天的记录统计
                        TodayStatistics(todayStats: todayStats, unitManager: unitManager)

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

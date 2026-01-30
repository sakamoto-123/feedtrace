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
    
    // 记录列表：编辑 / 删除 / 创建 / 彩蛋
    private struct RecordEditConfig: Identifiable {
        let id: UUID
    }
    @State private var editConfig: RecordEditConfig?
    @State private var showingDeleteConfirmation = false
    @State private var recordToDeleteId: UUID?
    @State private var isNavigatingToCreate = false
    @State private var showConfetti = false
    @State private var navigationPath = NavigationPath()
    
    private var recordToDelete: Record? {
        guard let recordToDeleteId = recordToDeleteId else { return nil }
        return records.first(where: { $0.id == recordToDeleteId })
    }
    
    /// 按天分组的记录
    private var recordsByDay: [Date: [Record]] {
        var grouped: [Date: [Record]] = [:]
        let calendar = Calendar.current
        for record in records {
            let date = calendar.startOfDay(for: record.startTimestamp)
            if grouped[date] == nil { grouped[date] = [] }
            grouped[date]?.append(record)
        }
        return grouped
    }
    
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
    
    // 最新生长数据
    private var latestGrowthData: GrowthData {
        baby.getLatestGrowthData(from: Array(records))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 0) {
                    BabyInfoHeader(baby: baby, latestGrowthData: latestGrowthData, showingBabySwitcher: $showingBabySwitcher)
                    
                    ScrollView {
                        HStack{}.frame(height: 8)
                        VStack(spacing: 16) {
                            if !ongoingRecords.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(ongoingRecords, id: \.id) { record in
                                        OngoingRecordCard(recordId: record.id)
                                    }
                                }
                            }
                            
                            TodayStatistics(baby: baby, todayStats: todayStats, unitManager: unitManager)
                            
                            RecordListContent(
                                recordsByDay: recordsByDay,
                                onEdit: { record in
                                    editConfig = RecordEditConfig(id: record.id)
                                },
                                onDelete: { record in
                                    recordToDeleteId = record.id
                                    showingDeleteConfirmation = true
                                },
                                style: .stack
                            )

                            HStack{}.frame(height: 90)
                        }
                    }
                }
                .background(Color.themeBackground(for: colorScheme))
                .toolbar(.hidden, for: .navigationBar)
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
                .sheet(isPresented: $showingBabyCreation) {
                    BabyCreationView(isEditing: false, isFirstCreation: false)
                }
                .sheet(item: $editConfig) { config in
                    RecordEditView(baby: baby, existingRecordId: config.id)
                }
                .sheet(isPresented: $isNavigatingToCreate) {
                    RecordEditView(baby: baby) { subCategory in
                        if subCategory.hasPrefix("first_") {
                            showConfetti = true
                        }
                    }
                }
                .alert("confirm_delete_record_title".localized, isPresented: $showingDeleteConfirmation) {
                    Button("cancel".localized, role: .cancel) {
                        recordToDeleteId = nil
                    }
                    Button("delete".localized, role: .destructive) {
                        if let record = recordToDelete {
                            viewContext.delete(record)
                            try? viewContext.save()
                        }
                        recordToDeleteId = nil
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    QuickActionsBarView(baby: baby)
                        .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(true)

                ConfettiCannon(
                    trigger: $showConfetti,
                    num: 50,
                    confettis: ConfettiType.allCases,
                    colors: [.red, .green, .blue, .yellow, .purple, .orange, .pink],
                    confettiSize: 8.0,
                    rainHeight: 600.0,
                    fadesOut: true,
                    opacity: 1.0,
                    openingAngle: Angle(degrees: 0),
                    closingAngle: Angle(degrees: 360),
                    radius: 200.0,
                    repetitions: 1,
                    repetitionInterval: 0.5,
                    hapticFeedback: true
                )
            }
            .ignoresSafeArea(edges: .bottom)
            // .overlay(alignment: .bottomTrailing) {
            //     if navigationPath.isEmpty {
            //         Button(action: {
            //             isNavigatingToCreate = true
            //         }) {
            //             Image(systemName: "plus")
            //                 .font(.title2)
            //                 .fontWeight(.semibold)
            //                 .foregroundColor(.white)
            //                 .frame(width: 56, height: 56)
            //                 .background(Color.accentColor)
            //                 .clipShape(Circle())
            //                 .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            //         }
            //         .padding(.trailing, 20)
            //         .padding(.bottom, 100)
            //     }
            // }
            .onChange(of: showConfetti) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showConfetti = false
                    }
                }
            }
        }
    }
}

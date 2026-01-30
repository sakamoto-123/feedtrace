import SwiftUI
import CoreData

struct RecordListView: View {
    let baby: Baby
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest private var records: FetchedResults<Record>
    
    init(baby: Baby) {
        self.baby = baby
        let babyId = baby.id
        _records = FetchRequest<Record>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Record.startTimestamp, ascending: false)],
            predicate: NSPredicate(format: "baby.id == %@", babyId as CVarArg),
            animation: .default)
    }
    
    // 按天分组的记录
    private var recordsByDay: [Date: [Record]] {
        var grouped: [Date: [Record]] = [:]
        let calendar = Calendar.current
        
        for record in records {
            let date = calendar.startOfDay(for: record.startTimestamp)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(record)
        }
        
        return grouped
    }
    
    // 导航状态
    @State private var isNavigatingToCreate = false
    // 编辑状态配置
    struct RecordEditConfig: Identifiable {
        let id: UUID
    }
    @State private var editConfig: RecordEditConfig?
    
    @State private var showConfetti = false
    // 导航路径，用于检测是否在根页面
    @State private var navigationPath = NavigationPath()
    
    // 删除确认 - 只存储要删除的记录ID，不存储实例，避免持有失效的模型引用
    @State private var showingDeleteConfirmation = false
    @State private var recordToDeleteId: UUID?
    
    // 计算属性：从当前有效的 records 数组中获取要删除的记录实例
    private var recordToDelete: Record? {
        guard let recordToDeleteId = recordToDeleteId else { return nil }
        return records.first(where: { $0.id == recordToDeleteId })
    }
    
    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                List {
                    RecordListContent(
                        recordsByDay: recordsByDay,
                        onEdit: { record in
                            editConfig = RecordEditConfig(id: record.id)
                        },
                        onDelete: { deleteRecord($0) },
                        style: .list
                    )
                }
                .listStyle(.insetGrouped)
                .padding(.top, 0)
                .navigationTitle("records".localized)
                .navigationBarTitleDisplayMode(.inline)
                // 编辑页面以 sheet 形式弹出
                .sheet(item: $editConfig) { config in
                    RecordEditView(baby: baby, existingRecordId: config.id)
                }
                // 创建页面以 sheet 形式弹出
                .sheet(isPresented: $isNavigatingToCreate) {
                    RecordEditView(baby: baby) {
                        subCategory in
                        if subCategory.hasPrefix("first_") {
                            showConfetti = true
                        }
                    }
                }
            }
            
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
            
            // 固定悬浮在右下角的添加按钮（只在 List 页面显示）
            if navigationPath.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // 导航到创建记录页面
                            isNavigatingToCreate = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        // 删除确认弹窗
        .alert("confirm_delete_record_title".localized, isPresented: $showingDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) {
                // 取消时重置状态
                recordToDeleteId = nil
            }
            Button("delete".localized, role: .destructive) {
                // 删除记录
                if let record = recordToDelete {
                    viewContext.delete(record)
                    // 保存更改
                    do {
                        try viewContext.save()
                    } catch {
                        // 如果保存失败，记录错误（可以添加错误提示）
                        print("删除记录失败: \(error.localizedDescription)")
                    }
                }
                // 重置状态
                recordToDeleteId = nil
            }
        }
        .onChange(of: showConfetti) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showConfetti = false
                }
            }
        }
    }
    
    private func deleteRecord(_ record: Record) {
        // 只存储ID，不存储实例，避免持有失效的模型引用
        recordToDeleteId = record.id
        showingDeleteConfirmation = true
    }
}

import SwiftUI
import SwiftData

// MARK: - 单个记录项组件
struct RecordItem: View {
    let record: Record
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: RecordDetailView(record: record)) {
            HStack(spacing: 12) {
                // 左侧：icon
                Text(record.icon)
                    .font(.title)
                    .frame(width: 40)
                
                // 中侧：名称、内容、时间、备注
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.subCategory.localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(formatRecordContent(record))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 5) {
                        Text(record.startTimestamp, format: Date.FormatStyle(time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let name = record.name, !name.isEmpty {
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let remark = record.remark, !remark.isEmpty {
                            Text(remark)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // 右侧：图片列表
                RecordPhotosPreview(photos: record.photos ?? [])
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                // 编辑记录
                onEdit()
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .tint(.accentColor)
            
            Button(role: .destructive) {
                // 删除记录
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
    
    // 格式化记录内容
    private func formatRecordContent(_ record: Record) -> String {
        let subCategory = record.subCategory
        
        switch subCategory {
        case "nursing", "sleep":
            var label = ""
            if let breastType = record.breastType {
                label =  breastType == "BOTH" ? "both_sides".localized : breastType == "LEFT" ? "left_side".localized : "right_side".localized
            }

            if let dayOrNight = record.dayOrNight {
               label = dayOrNight == "DAY" ? "daytime".localized + "☀️" : "night".localized + "🌙"
            }

            if let endTime = record.endTimestamp {
                return label + " " + localizedDuration(from: record.startTimestamp, to: endTime)
            } else {
                return label + " " + "in_progress".localized
            }
        case "pumping":
            var label = ""
            if let breastType = record.breastType {
                label =  breastType == "BOTH" ? "both_sides".localized : breastType == "LEFT" ? "left_side".localized : "right_side".localized
            }
            
            if let value = record.value, let unit = record.unit {
                return label + " " + "\(value.smartDecimal) \(unit)"
            }
        case "breast_bottle", "formula", "water_intake":
            if let value = record.value, let unit = record.unit {
                return "\(value.smartDecimal) \(unit)"
            }
        case "weight":
            if let value = record.value, let unit = record.unit {
                return "\(value.smartDecimal) \(unit)"
            }
        case "height":
            if let value = record.value, let unit = record.unit {
                return "\(value) \(unit)"
            }
        case "head":
            if let value = record.value, let unit = record.unit {
                return "\(value.smartDecimal) \(unit)"
            }
        case "temperature":
            if let value = record.value, let unit = record.unit {
                return "\(value.smartDecimal)°\(unit)"
            }
        case "diaper":
            if let status = record.excrementStatus {
                return status.lowercased().localized
            }
        case "solid_food":
            if let acceptance = record.acceptance {
                return acceptance.lowercased().localized
            }
        // case "medical_visit":
        //     if let name = record.name {
        //         return name
        //     }
        case "medication":
            if let value = record.value, let unit = record.unit {
                return "(value) \(unit)"
            }
        case "supplement":
            if let value = record.value, let unit = record.unit {
                return "(value) \(unit)"
            }
        // case "vaccination":
        //     if let name = record.name {
        //         return name
        //     }
        default:
            break
        }
        
        return ""
    }
}

// MARK: - 记录照片预览组件
struct RecordPhotosPreview: View {
    let photos: [Data]
    
    var body: some View {
        if !photos.isEmpty {
            HStack(alignment: .center, spacing: -26) {
                ForEach(photos.prefix(3).indices, id: \.self) {
                    index in
                    let photoData = photos[index]
                    if let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .cornerRadius(18)
                    }
                }
                
                if photos.count > 3 {
                    Text("+\(photos.count - 3)")
                        .font(.caption)
                        .padding(.leading, 30)
                }
            }
        }
    }
}

struct RecordListView: View {
    let baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [Record]
    
    init(baby: Baby) {
        self.baby = baby
        let babyId = baby.id
        _records = Query(filter: #Predicate { $0.babyId == babyId }, sort: [SortDescriptor(\Record.startTimestamp, order: .reverse)])
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
    @State private var isNavigatingToEdit = false
    @State private var isNavigatingToCreate = false
    // 只存储选中的记录ID，不存储实例，避免持有失效的模型引用
    @State private var selectedRecordId: UUID?
    @State private var showConfetti = false
    
    // 计算属性：从当前有效的 records 数组中获取选中的记录实例
    private var selectedRecord: Record? {
        guard let selectedRecordId = selectedRecordId else { return nil }
        return records.first(where: { $0.id == selectedRecordId })
    }
    
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
            NavigationStack {
                List {
                    ForEach(recordsByDay.sorted(by: { $0.key > $1.key }), id: \.key) { date, dayRecords in
                        Section(header: Text(formatDate(date))) {
                            ForEach(dayRecords.sorted(by: { $0.startTimestamp > $1.startTimestamp }), id: \.id) { record in
                                RecordItem(
                                    record: record,
                                    onEdit: {
                                        // 只存储ID，不存储实例
                                        selectedRecordId = record.id
                                        isNavigatingToEdit = true
                                    },
                                    onDelete: {
                                        deleteRecord(record)
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.top, 0)
                .navigationTitle("records".localized)
                .navigationBarTitleDisplayMode(.inline)
                // 编辑页面以 sheet 形式弹出
                .sheet(isPresented: $isNavigatingToEdit) {
                    if let record = selectedRecord {
                        RecordEditView(baby: baby, existingRecord: record)
                    }
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
                repetitions: 3,
                repetitionInterval: 0.5,
                hapticFeedback: true
            )
            
            // 固定悬浮在右下角的添加按钮
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
        // 删除确认弹窗
        .alert("确定删除记录吗？",  isPresented: $showingDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) {
                // 取消时重置状态
                recordToDeleteId = nil
            }
            Button("delete".localized, role: .destructive) {
                // 删除记录
                if let record = recordToDelete {
                    modelContext.delete(record)
                    // 保存更改
                    do {
                        try modelContext.save()
                    } catch {
                        // 如果保存失败，记录错误（可以添加错误提示）
                        print("删除记录失败: \(error.localizedDescription)")
                    }
                }
                // 重置状态
                recordToDeleteId = nil
            }
        }
        .onChange(of: showConfetti) {
            if $0 {
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

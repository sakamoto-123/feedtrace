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
                    
                    HStack(spacing: 8) {
                        Text(record.startTimestamp, format: Date.FormatStyle(time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                Label("edit".localized, systemImage: "square.and.pencil")
            }
            .tint(.accentColor)
            
            Button(role: .destructive) {
                // 删除记录
                onDelete()
            } label: {
                Label("delete".localized, systemImage: "trash")
            }
        }
    }
    
    // 格式化记录内容
    private func formatRecordContent(_ record: Record) -> String {
        let subCategory = record.subCategory
        
        switch subCategory {
        case "nursing", "sleep", "pumping":
            if let endTime = record.endTimestamp {
                let duration = endTime.timeIntervalSince(record.startTimestamp)
                let minutes = Int(duration / 60)
                return "\(minutes) " + "minutes".localized
            } else {
                return "in_progress".localized
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
        case "excrement":
            if let status = record.excrementStatus {
                return status.localized
            }
        case "solid_food":
            if let name = record.name, let acceptance = record.acceptance {
                return "\(name) · \(acceptance.localized)"
            } else if let name = record.name {
                return name
            } else if let acceptance = record.acceptance {
                return acceptance.localized
            }
        case "medical_visit":
            if let name = record.name {
                return name
            }
        case "medication":
            if let name = record.name, let value = record.value, let unit = record.unit {
                return "\(name) · \(value) \(unit)"
            } else if let name = record.name {
                return name
            }
        case "supplement":
            if let name = record.name, let value = record.value, let unit = record.unit {
                return "\(name) · \(value) \(unit)"
            } else if let name = record.name {
                return name
            }
        case "vaccination":
            if let name = record.name {
                return name
            }
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
            HStack(spacing: -26) {
                ForEach(photos.prefix(3).indices, id: \.self) {
                    index in
                    let photoData = photos[index]
                    if let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .cornerRadius(18)
                            .overlay(
                                Circle()
                                    .stroke(.secondary, lineWidth: 2)
                            )
                    }
                }
                
                if photos.count > 3 {
                    Text("+\(photos.count - 3)")
                        .font(.caption2)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray3))
                        .cornerRadius(6)
                        .foregroundColor(.secondary)
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
    @State private var selectedRecord: Record?
    @State private var showConfetti = false
    
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
                                        selectedRecord = record
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
                .navigationTitle("records".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // 导航到创建记录页面
                            isNavigatingToCreate = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
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
        modelContext.delete(record)
    }
}

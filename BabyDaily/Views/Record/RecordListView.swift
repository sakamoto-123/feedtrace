import SwiftUI
import SwiftData

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
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(recordsByDay.sorted(by: { $0.key > $1.key }), id: \.key) { date, dayRecords in
                    Section(header: Text(formatDate(date))) {
                        ForEach(dayRecords.sorted(by: { $0.startTimestamp > $1.startTimestamp }), id: \.id) { record in
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
                                    if let photos = record.photos, !photos.isEmpty {
                                        HStack(spacing: -26) {
                                            ForEach(photos.prefix(3).indices, id: \.self) { index in
                                                let photoData = photos[index]
                                                if let uiImage = UIImage(data: photoData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 36, height: 36)
                                                        .cornerRadius(18)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.gray, lineWidth: 2)
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    // 编辑记录
                    selectedRecord = record
                    isNavigatingToEdit = true
                } label: {
                    Label("edit".localized, systemImage: "square.and.pencil") // 更换为 square.and.pencil 图标
                }
                .tint(.accentColor)
                
                Button(role: .destructive) {
                    // 删除记录
                    deleteRecord(record)
                } label: {
                    Label("delete".localized, systemImage: "trash")
                }
            }
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
                RecordEditView(baby: baby)
            }
        }
    }
    
    private func deleteRecord(_ record: Record) {
        modelContext.delete(record)
    }
}

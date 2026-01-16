import SwiftUI
import SwiftData

struct RecordListView: View {
    let baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [Record] // 这里需要过滤当前宝宝的记录
    
    // 模拟记录数据
    @State private var allRecords: [Record] = []
    
    // 按天分组的记录
    private var recordsByDay: [Date: [Record]] {
        var grouped: [Date: [Record]] = [:]
        let calendar = Calendar.current
        
        for record in allRecords {
            let date = calendar.startOfDay(for: record.startTimestamp)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(record)
        }
        
        return grouped
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date, to: now)
        
        if components.day == 0 {
            return "today".localized
        } else if components.day == 1 {
            return "yesterday".localized
        } else {
            return date.formatted(Date.FormatStyle(date: .long))
        }
    }
    
    // 格式化记录内容
    private func formatRecordContent(_ record: Record) -> String {
        switch record.subCategory {
        case "亲喂":
            if let end = record.endTimestamp {
                let duration = end.timeIntervalSince(record.startTimestamp)
                let minutes = Int(duration / 60)
                return "左 \(minutes/2) 分钟，右 \(minutes/2) 分钟"
            } else {
                return "进行中"
            }
        case "辅食":
            if let name = record.name, let value = record.value, let unit = record.unit {
                return "\(name) \(value)\(unit)"
            } else {
                return record.subCategory
            }
        case "奶粉", "水", "母乳":
            if let value = record.value, let unit = record.unit {
                return "\(value)\(unit)"
            } else {
                return record.subCategory
            }
        case "睡觉":
            if let end = record.endTimestamp {
                let duration = end.timeIntervalSince(record.startTimestamp)
                let hours = Int(duration / 3600)
                let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                if hours > 0 {
                    return "\(hours)小时\(minutes)分钟"
                } else {
                    return "\(minutes)分钟"
                }
            } else {
                return "进行中"
            }
        default:
            return record.subCategory
        }
    }
    
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
                                            Text(record.subCategory)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(".\(formatRecordContent(record))")
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
                                        HStack(spacing: -8) {
                                            ForEach(photos.prefix(3), id: \.self) {
                                                photoData in
                                                if let uiImage = UIImage(data: photoData) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 36, height: 36)
                                                        .cornerRadius(6)
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
                                Button(role: .destructive) {
                                    // 删除记录
                                    deleteRecord(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                
                                Button {
                                    // 编辑记录
                                    // 导航到编辑页面
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 导航到创建记录页面
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func deleteRecord(_ record: Record) {
        // 删除记录
    }
}
import SwiftUI
import CoreData

// 进行中记录卡片组件
struct OngoingRecordCard: View {
    let recordId: UUID
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 只查询目标 Record，避免订阅全量 records
    @FetchRequest private var records: FetchedResults<Record>
    
    init(recordId: UUID) {
        self.recordId = recordId
        _records = FetchRequest<Record>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", recordId as CVarArg))
    }
    
    // 当前记录（理论上最多 1 条）
    private var record: Record? { records.first }
    
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
        if let record = record {
            HStack(spacing: 12) {
                // 左侧可点击区域
                HStack(spacing: 12) {
                    Text(record.icon)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text("\(record.subCategory?.localized ?? "")")
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
                        try viewContext.save()
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
                RecordDetailView(recordId: record.id)
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
}

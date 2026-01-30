//
//  RecordListContent.swift
//  BabyDaily
//
// 按天分组的记录列表可复用组件，支持 List 内 Section 与独立 VStack 区块两种形态。
//

import SwiftUI
import CoreData

enum RecordListContentStyle {
    /// 用于 List { } 内，返回多个 Section，支持 swipeActions
    case list
    /// 用于独立区块（如首页），带日期标题 + RecordItem，无 List
    case stack
}

struct RecordListContent: View {
    let recordsByDay: [Date: [Record]]
    let onEdit: (Record) -> Void
    let onDelete: (Record) -> Void
    var style: RecordListContentStyle = .list
    
    @Environment(\.colorScheme) private var colorScheme

    private let volumeUnit = UnitManager.shared.volumeUnit.rawValue

    private var sortedDays: [(key: Date, value: [Record])] {
        Array(recordsByDay.sorted(by: { $0.key > $1.key }))
    }
    
    var body: some View {
        switch style {
        case .list:
            listContent
        case .stack:
            stackContent
        }
    }
    
    /// List 内使用：多个 Section，左滑生效
    private var listContent: some View {
        ForEach(Array(sortedDays.enumerated()), id: \.offset) { _, item in
            Section(header: HStack {
                Text(formatDate(item.key))
                Spacer()
                dailyStatsSummary(records: item.value)
            }) {
                ForEach(item.value.sorted(by: { $0.startTimestamp > $1.startTimestamp }), id: \.id) { (record: Record) in
                    RecordItem(
                        record: record,
                        onEdit: { onEdit(record) },
                        onDelete: { onDelete(record) }
                    )
                }
            }
        }
    }
    
    /// 独立区块：标题 + 卡片 + 按天分组
    private var stackContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("records".localized)
                .font(.headline)
                .padding(.top, 12)

            ForEach(Array(sortedDays.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDate(item.key))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        dailyStatsSummary(records: item.value)
                    }.padding(.bottom, 16)
                    .padding(.top, 20)

                    ForEach(item.value.sorted(by: { $0.startTimestamp > $1.startTimestamp }), id: \.id) { (record: Record) in
                        VStack(alignment: .leading, spacing: 0) {
                            RecordItem(
                                record: record,
                                onEdit: { onEdit(record) },
                                onDelete: { onDelete(record) }
                            )
                            
                            GeometryReader { geometry in
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                                }
                                .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            }
                            .frame(height: 1)  // 限制高度，避免 GeometryReader 占满剩余空间导致 item 间留白
                            .padding(.leading, 52)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 12)
    }

    /// 某一天的统计摘要：奶粉量、母乳量、睡觉时长（用于日期行右侧）
    private func dailyStatsSummary(records: [Record]) -> some View {
        let stats = StatsCalculator.getDailyStatsFromRecords(records)
        let formulaText: String = "formula".localized + " " + stats.formulaAmount.smartDecimal + volumeUnit
        let breastMilkText: String = "breast_milk".localized + " " + stats.breastMilkAmount.smartDecimal + volumeUnit
        let sleepText: String = "sleep".localized + " " + stats.sleepDurationInHours.smartDecimal + " " + "hour_unit".localized
        return HStack(spacing: 10) {
            Text(formulaText)
            Text(breastMilkText)
            Text(sleepText)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

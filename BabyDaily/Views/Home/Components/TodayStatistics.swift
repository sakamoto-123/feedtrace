import SwiftUI

// 今日统计信息组件
struct TodayStatistics: View {
    let todayStats: DailyStats
    let unitManager: UnitManager
    @Environment(\.colorScheme) private var colorScheme

    private func recordValueText(_ record: Record) -> String {
        return " \(record.value.smartDecimal) \(record.unit ?? "")"
    }

    private var feedingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("feeding".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("formula".localized + "colon_separator".localized + "\(todayStats.formulaAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Text("breast_milk".localized + "colon_separator".localized + "\(todayStats.breastMilkAmount.smartDecimal) \(unitManager.volumeUnit.rawValue)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sleep".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("duration_label".localized + "colon_separator".localized + "\(todayStats.sleepDurationInHours.smartDecimal) " + "hour_unit".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Text("count_label".localized + "colon_separator".localized + "\(todayStats.sleepCount) " + "times".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var supplementSection: some View {
        if !todayStats.supplementRecords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("supplement".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(todayStats.supplementRecords, id: \.id) { record in
                    Text("\(record.name ?? "")\(recordValueText(record))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var solidFoodSection: some View {
        if !todayStats.solidFoodRecords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("solid_food".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(todayStats.solidFoodRecords, id: \.id) { record in
                    Text("\(record.name ?? "")\(recordValueText(record))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("today_statistics".localized)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], alignment: .leading, spacing: 24) {
                feedingSection
                sleepSection
                supplementSection
                solidFoodSection
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

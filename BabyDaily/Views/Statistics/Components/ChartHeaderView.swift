import SwiftUI

// 图表标题组件
struct ChartTitleView: View {
    let title: String
    let timeRange: String
    
    var body: some View {
        HStack {
            Text(title.localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            Text(timeRange.localized)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

// 图例项组件
struct LegendItem: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundColor(color)
            Text(title.localized)
                .font(.system(size: 14))
                .foregroundColor(.black)
        }
    }
}

// 选项卡和时间范围选择器组件
struct ChartHeaderView: View {
    @Binding var selectedTab: String
    @Binding var timeRange: String
    
    var body: some View {
        HStack {
            // 选项卡
            Picker("", selection: $selectedTab) {
                Text("feeding_trend".localized).tag("feeding_trend")
                Text("sleep_trend".localized).tag("sleep_trend")
                Text("growth_statistics".localized).tag("growth_statistics")
                Text("daily_activity".localized).tag("daily_activity")
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
            
            // 时间范围选择
            Menu {
                Button("7_days".localized) { timeRange = "7_days" }
                Button("30_days".localized) { timeRange = "30_days" }
                Button("90_days".localized) { timeRange = "90_days" }
                Button("12_months".localized) { timeRange = "12_months" }
            } label: {
                HStack {
                    Text(timeRange.localized)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.leading, 12)
        }
        .padding(.horizontal)
    }
}
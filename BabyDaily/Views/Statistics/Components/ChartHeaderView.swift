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

// 时间范围选择器组件 - 使用分段选择器
struct TimeRangeSegmentView: View {
    @Binding var timeRange: String
    
    var body: some View {
        Picker("", selection: $timeRange) {
            Text("7_days".localized).tag("7_days")
            Text("14_days".localized).tag("14_days")
            Text("30_days".localized).tag("30_days")
            // Text("90_days".localized).tag("90_days")
            // Text("12_months".localized).tag("12_months")
        }
        .pickerStyle(.segmented)
        .frame(height: 32)
    }
}

// 成长维度选择器组件 - 使用分段选择器
struct GrowthDimensionSegmentView: View {
    @Binding var selectedDimension: String
    
    var body: some View {
        Picker("", selection: $selectedDimension) {
            Text("weight".localized).tag("weight")
            Text("height".localized).tag("height")
            Text("head".localized).tag("head")
            Text("bmi".localized).tag("bmi")
        }
        .pickerStyle(.segmented)
        .frame(height: 32)
    }
}

// 选项卡组件
struct ChartHeaderView: View {
    @Binding var selectedTab: String
    @Binding var timeRange: String
    @Binding var selectedDimension: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // 选项卡
            Picker("", selection: $selectedTab) {
                Text("feeding_trend".localized).tag("feeding_trend")
                Text("sleep_trend".localized).tag("sleep_trend")
                Text("growth_statistics".localized).tag("growth_statistics")
                // Text("daily_activity".localized).tag("daily_activity")
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)
            
            // 根据选项卡显示不同的segment组件
            if selectedTab == "feeding_trend" || selectedTab == "sleep_trend" {
                // 时间范围选择器
                TimeRangeSegmentView(timeRange: $timeRange)
            } else if selectedTab == "growth_statistics" {
                // 成长维度选择器
                GrowthDimensionSegmentView(selectedDimension: $selectedDimension)
            }
        }
        .padding()
        .padding(.top, 0)
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
    }
}
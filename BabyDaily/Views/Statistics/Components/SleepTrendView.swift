import SwiftUI
import Charts

// 睡眠时间卡片
struct SleepDurationCard: View {
    let data: [(date: Date, duration: Double, count: Int)]
    @Binding var selectedData: (date: Date, duration: Double)?
    let timeRange: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            ChartTitleView(title: "sleep_duration_title", timeRange: timeRange)
                .padding(.horizontal, 20)
            
            // 图表区域
            Chart(data, id: \.date) {
                LineMark(
                    x: .value("date", $0.date),
                    y: .value("hours_unit", $0.duration)
                )
                .foregroundStyle(.purple)
                .symbol(.circle)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("date", $0.date),
                    y: .value("hours_unit", $0.duration)
                )
                .foregroundStyle(Color.purple.opacity(0.2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks() {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartOverlay {
                proxy in
                GeometryReader {
                    geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover {
                            hover in
                            guard case .active(let location) = hover,
                                  let date: Date = proxy.value(atX: location.x)
                            else {
                                selectedData = nil
                                return
                            }
                            if let data = self.data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                selectedData = (date: data.date, duration: data.duration)
                            }
                        }
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)
            
            // 选中数据显示
            if let selectedData = selectedData {
                HStack(spacing: 24) {
                    Text(String(format: "sleep_duration_format".localized, selectedData.duration))
                        .font(.system(size: 14))
                        .foregroundColor(.purple)
                    Spacer()
                    Text(selectedData.date, format: .dateTime.month().day())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 睡眠次数卡片
struct SleepCountCard: View {
    let data: [(date: Date, duration: Double, count: Int)]
    @Binding var selectedData: (date: Date, count: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            ChartTitleView(title: "sleep_count_title", timeRange: timeRange)
                .padding(.horizontal, 20)
            
            // 图表区域
            Chart(data, id: \.date) {
                BarMark(
                    x: .value("date", $0.date),
                    y: .value("times_unit", $0.count)
                )
                .foregroundStyle(.green.opacity(0.8))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks() {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartOverlay {
                proxy in
                GeometryReader {
                    geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover {
                            hover in
                            guard case .active(let location) = hover,
                                  let date: Date = proxy.value(atX: location.x)
                            else {
                                selectedData = nil
                                return
                            }
                            if let data = self.data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                selectedData = (date: data.date, count: data.count)
                            }
                        }
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)
            
            // 选中数据显示
            if let selectedData = selectedData {
                HStack(spacing: 24) {
                    Text(String(format: "sleep_count_format".localized, selectedData.count))
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Spacer()
                    Text(selectedData.date, format: .dateTime.month().day())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(.background)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 睡眠趋势组合视图
struct SleepTrendView: View {
    let data: [(date: Date, duration: Double, count: Int)]
    @Binding var selectedDuration: (date: Date, duration: Double)?
    @Binding var selectedCount: (date: Date, count: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(spacing: 20) {
            SleepDurationCard(data: data, selectedData: $selectedDuration, timeRange: timeRange)
            SleepCountCard(data: data, selectedData: $selectedCount, timeRange: timeRange)
        }
        .padding(.bottom, 20)
    }
}
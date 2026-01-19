import SwiftUI
import Charts

// 睡眠时长图表子组件
private struct SleepDurationChart: View {
    let data: [(date: Date, duration: Int, count: Int)]
    
    var body: some View {
        Chart(data, id: \.date) {item in
            BarMark(
                x: .value("date", item.date),
                y: .value("hours_unit", item.duration),
                width: 28,            )
            .foregroundStyle(.green.opacity(0.8))
            .cornerRadius(4)
            .annotation(position: .overlay, alignment: .top) {
                if item.duration > 0 {
                    Text("\(item.duration)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 240)
        .padding(.horizontal, 8)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: TimeInterval(7 * 86400 * 1.05))
//        .chartYScale(domain: .automatic(includesZero: true))
        .chartYScale(domain: 0...20)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.12))
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day(.defaultDigits))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.12))
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

// 睡眠次数图表子组件
private struct SleepCountChart: View {
    let data: [(date: Date, duration: Int, count: Int)]
    
    var body: some View {
        Chart(data, id: \.date) {item in 
            BarMark(
                x: .value("date", item.date),
                y: .value("times_unit", item.count),
                width: 28,            )
            .foregroundStyle(.green.opacity(0.8))
            .cornerRadius(4)
            .annotation(position: .overlay, alignment: .top) {
                if item.count > 0 {
                    Text("\(item.count)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 240)
        .padding(.horizontal, 8)
//        .chartYScale(domain: .automatic(includesZero: true))
        .chartYScale(domain: 0...15)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: TimeInterval(7 * 86400 * 1.05))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.12))
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day(.defaultDigits))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
        }
      
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.12))
                AxisValueLabel()
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

// 睡眠时间卡片
struct SleepDurationCard: View {
    let data: [(date: Date, duration: Int, count: Int)]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("睡眠时长(" + "小时" + ")")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            
            // 使用提取的子组件
            SleepDurationChart(data: data)
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal)
    }
}

// 睡眠次数卡片
struct SleepCountCard: View {
    let data: [(date: Date, duration: Int, count: Int)]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("睡眠次数")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            
            // 使用提取的子组件
            SleepCountChart(data: data)
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal)
    }
}

// 睡眠趋势组合视图
struct SleepTrendView: View {
    let data: [(date: Date, duration: Int, count: Int)]
    
    var body: some View {
        VStack(spacing: 16) {
            SleepDurationCard(data: data)
            SleepCountCard(data: data)
        }
    }
}

import SwiftUI
import Charts

// 奶量趋势卡片
struct FeedingVolumeCard: View {
    let data: [(date: Date, breastMilk: Int, formula: Int)]
    @Binding var selectedData: (date: Date, breastMilk: Int, formula: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            ChartTitleView(title: "feeding_trend_title", timeRange: timeRange)
                .padding(.horizontal, 20)
            
            // 图表区域
            Chart {
                ForEach(data, id: \.date) {
                    // 母乳曲线
                    LineMark(
                        x: .value("date", $0.date),
                        y: .value("milk_volume_unit", $0.breastMilk)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // 奶粉曲线
                    LineMark(
                        x: .value("date", $0.date),
                        y: .value("milk_volume_unit", $0.formula)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    // 曲线填充
                    AreaMark(
                        x: .value("date", $0.date),
                        y: .value("milk_volume_unit", $0.breastMilk)
                    )
                    .foregroundStyle(Color.red.opacity(0.2))
                    
                    AreaMark(
                        x: .value("date", $0.date),
                        y: .value("milk_volume_unit", $0.formula)
                    )
                    .foregroundStyle(Color.blue.opacity(0.2))
                }
            }
            .chartForegroundStyleScale(
                domain: ["breast_milk", "formula_milk"],
                range: [.red, .blue]
            )
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
                                selectedData = (date: data.date, breastMilk: data.breastMilk, formula: data.formula)
                            }
                        }
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)
            
            // 选中数据显示
            if let selectedData = selectedData {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("breast_milk".localized + ": \(selectedData.breastMilk) ml")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text("formula_milk".localized + ": \(selectedData.formula) ml")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Text(selectedData.date, format: .dateTime.month().day())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
            }
            
            // 图例
            HStack(spacing: 24) {
                LegendItem(title: "breast_milk", color: .red)
                LegendItem(title: "formula_milk", color: .blue)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 喂养次数卡片
struct FeedingCountCard: View {
    let data: [(date: Date, breastMilk: Int, formula: Int)]
    @Binding var selectedData: (date: Date, breastMilk: Int, formula: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            ChartTitleView(title: "feeding_count_title", timeRange: timeRange)
                .padding(.horizontal, 20)
            
            // 图表区域
            Chart {
                ForEach(data, id: \.date) {
                    data in
                    // 母乳柱状图
                    BarMark(
                        x: .value("date", data.date),
                        y: .value("times_unit", data.breastMilk)
                    )
                    .foregroundStyle(.red.opacity(0.8))
                    
                    // 奶粉柱状图
                    BarMark(
                        x: .value("date", data.date),
                        y: .value("times_unit", data.formula)
                    )
                    .foregroundStyle(.blue.opacity(0.8))
                }
            }
            .chartForegroundStyleScale(
                domain: ["breast_milk", "formula_milk"],
                range: [.red.opacity(0.8), .blue.opacity(0.8)]
            )
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
                                selectedData = (date: data.date, breastMilk: data.breastMilk, formula: data.formula)
                            }
                        }
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)
            
            // 选中数据显示
            if let selectedData = selectedData {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("breast_milk".localized + ": \(selectedData.breastMilk) " + "times".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text("formula_milk".localized + ": \(selectedData.formula) " + "times".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Text(selectedData.date, format: .dateTime.month().day())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
            }
            
            // 图例
            HStack(spacing: 24) {
                LegendItem(title: "breast_milk", color: .red)
                LegendItem(title: "formula_milk", color: .blue)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 喂养趋势组合视图
struct FeedingTrendView: View {
    let volumeData: [(date: Date, breastMilk: Int, formula: Int)]
    let countData: [(date: Date, breastMilk: Int, formula: Int)]
    @Binding var selectedVolumeData: (date: Date, breastMilk: Int, formula: Int)?
    @Binding var selectedCountData: (date: Date, breastMilk: Int, formula: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(spacing: 20) {
            FeedingVolumeCard(data: volumeData, selectedData: $selectedVolumeData, timeRange: timeRange)
            FeedingCountCard(data: countData, selectedData: $selectedCountData, timeRange: timeRange)
        }
        .padding(.bottom, 20)
    }
}
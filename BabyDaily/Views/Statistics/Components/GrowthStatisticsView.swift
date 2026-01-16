import SwiftUI
import Charts

// 成长统计卡片
struct GrowthStatisticsCard: View {
    let data: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)]
    @Binding var selectedData: (month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)?
    @Binding var selectedDimension: String
    let timeRange: String
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和维度选择
            VStack(spacing: 12) {
                ChartTitleView(title: "growth_statistics", timeRange: timeRange)
                
                // 维度选择器
                HStack(spacing: 12) {
                    ForEach(["weight", "height", "head_circumference", "bmi"], id: \.self) {
                        dimension in
                        Button(action: {
                            selectedDimension = dimension
                        }) {
                            Text(dimension.localized)
                                .font(.system(size: 14))
                                .foregroundColor(selectedDimension == dimension ? .white : .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedDimension == dimension ? Color.blue : Color(.systemGray5))
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 图表区域
            Chart(data, id: \.month) {
                // 根据选择的维度显示对应的曲线
                if selectedDimension == "weight" {
                    LineMark(
                        x: .value("month_age", $0.month),
                        y: .value("weight_kg", $0.weight)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("month_age", $0.month),
                        y: .value("weight_kg", $0.weight)
                    )
                    .foregroundStyle(Color.red.opacity(0.2))
                } else if selectedDimension == "height" {
                    LineMark(
                        x: .value("month_age", $0.month),
                        y: .value("height_cm", $0.height)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("month_age", $0.month),
                        y: .value("height_cm", $0.height)
                    )
                    .foregroundStyle(Color.blue.opacity(0.2))
                } else if selectedDimension == "head_circumference" {
                    LineMark(
                        x: .value("month_age", $0.month),
                        y: .value("head_circumference_cm", $0.headCircumference)
                    )
                    .foregroundStyle(.green)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("month_age", $0.month),
                        y: .value("head_circumference_cm", $0.headCircumference)
                    )
                    .foregroundStyle(Color.green.opacity(0.2))
                } else if selectedDimension == "bmi" {
                    LineMark(
                        x: .value("month_age", $0.month),
                        y: .value("bmi", $0.bmi)
                    )
                    .foregroundStyle(.orange)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("month_age", $0.month),
                        y: .value("bmi", $0.bmi)
                    )
                    .foregroundStyle(Color.orange.opacity(0.2))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>())
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
                                  let month: Int = proxy.value(atX: location.x)
                            else {
                                selectedData = nil
                                return
                            }
                            if let data = self.data.first(where: { $0.month == month }) {
                                selectedData = (month: data.month, weight: data.weight, height: data.height, headCircumference: data.headCircumference, bmi: data.bmi)
                            }
                        }
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 16)
            
            // 选中数据显示
            if let selectedData = selectedData {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: "month_age_format".localized, selectedData.month))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    HStack(spacing: 24) {
                        Text(String(format: "weight_format".localized, selectedData.weight))
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text(String(format: "height_format".localized, selectedData.height))
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text(String(format: "head_circumference_format".localized, selectedData.headCircumference))
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // 数据指标
            HStack(spacing: 24) {
                ForEach(["weight", "height", "head_circumference", "bmi"], id: \.self) {
                    dimension in
                    VStack(spacing: 8) {
                        Text(dimension.localized)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        if let latestData = data.last {
                            if dimension == "weight" {
                                Text(String(format: "%.1f kg", latestData.weight))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            } else if dimension == "height" {
                                Text(String(format: "%.1f cm", latestData.height))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            } else if dimension == "head_circumference" {
                                Text(String(format: "%.1f cm", latestData.headCircumference))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            } else if dimension == "bmi" {
                                Text(String(format: "%.1f", latestData.bmi.rounded(toPlaces: 1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 成长统计组合视图
struct GrowthStatisticsView: View {
    let data: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)]
    @Binding var selectedData: (month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)?
    @Binding var selectedDimension: String
    let timeRange: String
    
    var body: some View {
        VStack(spacing: 20) {
            GrowthStatisticsCard(data: data, selectedData: $selectedData, selectedDimension: $selectedDimension, timeRange: timeRange)
        }
        .padding(.bottom, 20)
    }
}
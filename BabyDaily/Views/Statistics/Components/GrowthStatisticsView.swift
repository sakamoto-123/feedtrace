import SwiftUI
import Charts

// 成长统计卡片
struct GrowthStatisticsCard: View {
    let data: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)]
    @Binding var selectedDimension: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和维度选择
            VStack(spacing: 12) {
                Text("growth_statistics".localized)
                    .font(.system(size: 17, weight: .semibold))
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
                } else if selectedDimension == "head" {
                    LineMark(
                        x: .value("month_age", $0.month),
                        y: .value("head_cm", $0.headCircumference)
                    )
                    .foregroundStyle(.green)
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("month_age", $0.month),
                        y: .value("head_cm", $0.headCircumference)
                    )
                    .foregroundStyle(Color.green.opacity(0.2))
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
            .frame(height: 250)
            .padding(.horizontal, 16)
            
            // 数据指标
            HStack(spacing: 24) {
                ForEach(["weight", "height", "head", "bmi"], id: \.self) {
                    dimension in
                    VStack(spacing: 8) {
                        Text(dimension.localized)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        if let latestData = data.last {
                            if dimension == "weight" {
                                Text("\(latestData.weight.smartDecimal) kg")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            } else if dimension == "height" {
                                Text("\(latestData.height.smartDecimal) cm")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            } else if dimension == "head" {
                                Text("\(latestData.headCircumference.smartDecimal) cm")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 成长统计组合视图
struct GrowthStatisticsView: View {
    let data: [(month: Int, weight: Double, height: Double, headCircumference: Double, bmi: Double)]
    @Binding var selectedDimension: String
    
    var body: some View {
        VStack(spacing: 20) {
            GrowthStatisticsCard(data: data, selectedDimension: $selectedDimension)
        }
        .padding(.bottom, 20)
    }
}
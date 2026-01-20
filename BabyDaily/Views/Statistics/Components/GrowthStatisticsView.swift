import SwiftUI
import Charts

// 导入数据模型
import Foundation

// MARK: - 图表数据点

struct GrowthChartDataPoint: Identifiable {
    let id = UUID()
    let month: Int
    let value: Double
    let series: String  // "5th", "25th", "50th", "75th", "95th"
    let isDashed: Bool  // 是否为虚线
}

// MARK: - 图表组件

struct GrowthStatisticsCard: View {
    let data: GrowthDataset
    @Environment(\.colorScheme) private var colorScheme
    
    private let colors: [Color] = [.blue, .green, .red, .orange, .purple]
    private let legendItems = ["5th", "25th", "50th", "75th", "95th"]
    
    @State private var xVisibleDomain: (Double, Double) = (0, 6)
    
    // 将原始数据转换为图表数据点
    private var chartData: [GrowthChartDataPoint] {
        var result: [GrowthChartDataPoint] = []
        
        for item in data.data {
            // 5th - 虚线
            result.append(GrowthChartDataPoint(
                month: item.month,
                value: item.fifth,
                series: "5th",
                isDashed: true
            ))
            // 25th - 虚线
            result.append(GrowthChartDataPoint(
                month: item.month,
                value: item.twentyFifth,
                series: "25th",
                isDashed: true
            ))
            // 50th - 实线
            result.append(GrowthChartDataPoint(
                month: item.month,
                value: item.fiftieth,
                series: "50th",
                isDashed: false
            ))
            // 75th - 虚线
            result.append(GrowthChartDataPoint(
                month: item.month,
                value: item.seventyFifth,
                series: "75th",
                isDashed: true
            ))
            // 95th - 虚线
            result.append(GrowthChartDataPoint(
                month: item.month,
                value: item.ninetyFifth,
                series: "95th",
                isDashed: true
            ))
        }
        
        return result
    }
    
    // 颜色映射字典
    private var colorScale: [String: Color] {
        let scale: [String: Color] = [
            "5th": colors[0],
            "25th": colors[1],
            "50th": colors[2],
            "75th": colors[3],
            "95th": colors[4]
        ]
        return scale
    }
    
    // 为每个系列预处理数据，避免在 Chart 闭包中进行复杂计算
    private var series5th: [GrowthChartDataPoint] {
        chartData.filter { $0.series == "5th" }
    }
    
    private var series25th: [GrowthChartDataPoint] {
        chartData.filter { $0.series == "25th" }
    }
    
    private var series50th: [GrowthChartDataPoint] {
        chartData.filter { $0.series == "50th" }
    }
    
    private var series75th: [GrowthChartDataPoint] {
        chartData.filter { $0.series == "75th" }
    }
    
    private var series95th: [GrowthChartDataPoint] {
        chartData.filter { $0.series == "95th" }
    }

    private var defaultDomain: ClosedRange<Double> {
        let dimension = data.dimension
        
        switch dimension {
        case "weight":
            return 1...22
        case "height":
            return 30...120
        case "head":
            return 25...60
        default:
            return 0...120
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 图表区域 - 简化实现
            makeGrowthChart()
            
            // 图例
            makeLegend()
        }
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 16)
    }
    
    // 图表绘制
    private func makeGrowthChart() -> some View {
        // 预处理数据，避免在闭包中访问计算属性
        let data5th = series5th
        let data25th = series25th
        let data50th = series50th
        let data75th = series75th
        let data95th = series95th
        
        // 定义线型样式
        let dashedStyle = StrokeStyle(lineWidth: 1, dash: [5, 5])
        let solidStyle = StrokeStyle(lineWidth: 1)
        
        // 先创建基础图表内容
        let chart = Chart {
            // 5th - 蓝色虚线
            ForEach(data5th) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value),
                    series: .value("Series", "5th")
                )
                .foregroundStyle(by: .value("Series", "5th"))
                .lineStyle(dashedStyle)
                .interpolationMethod(.catmullRom)
            }
            
            // 25th - 绿色虚线
            ForEach(data25th) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value),
                    series: .value("Series", "25th")
                )
                .foregroundStyle(by: .value("Series", "25th"))
                .lineStyle(dashedStyle)
                .interpolationMethod(.catmullRom)
            }
            
            // 50th - 红色实线
            ForEach(data50th) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value),
                    series: .value("Series", "50th")
                )
                .foregroundStyle(by: .value("Series", "50th"))
                .lineStyle(solidStyle)
                .interpolationMethod(.catmullRom)
            }
            
            // 75th - 橙色虚线
            ForEach(data75th) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value),
                    series: .value("Series", "75th")
                )
                .foregroundStyle(by: .value("Series", "75th"))
                .lineStyle(dashedStyle)
                .interpolationMethod(.catmullRom)
            }
            
            // 95th - 紫色虚线
            ForEach(data95th) { point in
                LineMark(
                    x: .value("Month", point.month),
                    y: .value("Value", point.value),
                    series: .value("Series", "95th")
                )
                .foregroundStyle(by: .value("Series", "95th"))
                .lineStyle(dashedStyle)
                .interpolationMethod(.catmullRom)
            }
        }
        
        // 应用所有配置
        return chart
            // .chartForegroundStyleScale(colorScale)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) {
                    AxisGridLine()
                    AxisValueLabel(format: IntegerFormatStyle<Int>.number)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .inset, position: .leading, values: .automatic(desiredCount: 5)) {
                    AxisGridLine()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1)))
                }
            }
            .chartYScale(domain: defaultDomain)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 7)
            .frame(height: 540)
            .padding()
    }
    
    // 图例
    private func makeLegend() -> some View {
        HStack(spacing: 12) {
            ForEach(0..<legendItems.count, id: \.self) {
                index in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(colors[index])
                        .frame(width: 6, height: 6)
                        .cornerRadius(5)
                    Text(legendItems[index])
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - 主视图

struct GrowthStatisticsView: View {
    let gender: String
    let dimension: String
    
    private var growthData: GrowthDataset {
        CSVReader.readGrowthData(for: gender, dimension: dimension)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            GrowthStatisticsCard(data: growthData)
        }
        .padding(.bottom, 20)
    }
}

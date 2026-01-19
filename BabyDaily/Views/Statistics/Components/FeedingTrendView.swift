import SwiftUI
import Charts

enum FeedingType: String, CaseIterable {
    case breastMilk, formula, water

    var color: Color {
        switch self {
        case .breastMilk:
            return Color(.systemBlue).opacity(0.65)
        case .formula:
            return Color(.systemOrange).opacity(0.65)
        case .water:
            return Color(.green).opacity(0.6)
        }
    }

    var title: String {
        switch self {
        case .breastMilk: return "母乳"
        case .formula: return "formula".localized
        case .water: return "water_intake".localized
        }
    }
}

struct FeedingStackItem: Identifiable {
    let id = UUID()
    let date: Date
    let type: FeedingType
    let value: Int
}

private struct ChartLegend: View {
    var body: some View {
        // 图例
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle()
                    .fill(FeedingType.breastMilk.color)
                    .frame(width: 8, height: 8)
                Text(FeedingType.breastMilk.title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Circle()
                    .fill(FeedingType.formula.color)
                    .frame(width: 8, height: 8)
                Text(FeedingType.formula.title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Circle()
                    .fill(FeedingType.water.color)
                    .frame(width: 8, height: 8)
                Text(FeedingType.water.title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

// 奶量趋势图表子组件
private struct FeedingBaseChart: View {
    let stackedData: [FeedingStackItem]
    
    var body: some View {
        Chart(stackedData) { item in
            BarMark(
                x: .value("date", item.date),
                y: .value("volume", item.value),
                width: 28,
            )
            .foregroundStyle(item.type.color)
            .annotation(position: .overlay, alignment: .center) {
                if item.value > 0 {
                    Text("\(item.value)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 240)
        .padding(.horizontal, 8)
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

// 奶量趋势卡片
struct FeedingVolumeCard: View {
    let data: [(date: Date, breastMilk: Int, formula: Int, water: Int)]
    @Environment(\.colorScheme) private var colorScheme
    // 单位管理
    @StateObject private var unitManager = UnitManager.shared

    // 添加明确的类型注解
    private var stackedData: [FeedingStackItem] {
        data.flatMap {
            [
                FeedingStackItem(date: $0.date, type: .breastMilk, value: $0.breastMilk),
                FeedingStackItem(date: $0.date, type: .formula, value: $0.formula),
                FeedingStackItem(date: $0.date, type: .water, value: $0.water)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack{
                Text("数量(" + unitManager.volumeUnit.rawValue + ")")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                ChartLegend()
            }
            
            // 使用提取的子组件
            FeedingBaseChart(stackedData: stackedData)
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// 喂养次数卡片
struct FeedingCountCard: View {
      let data: [(date: Date, breastMilkCount: Int, formulaCount: Int, waterCount: Int)]
    @Environment(\.colorScheme) private var colorScheme
    // 添加明确的类型注解
    private var stackedData: [FeedingStackItem] {
        data.flatMap {
            [
                FeedingStackItem(date: $0.date, type: .breastMilk, value: $0.breastMilkCount),
                FeedingStackItem(date: $0.date, type: .formula, value: $0.formulaCount),
                FeedingStackItem(date: $0.date, type: .water, value: $0.waterCount)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
               // 标题
            HStack{
                Text("喂养次数")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                ChartLegend()
            }
            
            // 使用提取的子组件
            FeedingBaseChart(stackedData: stackedData)
            
          
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// 喂养趋势组合视图
struct FeedingTrendView: View {
    let volumeData: [(date: Date, breastMilk: Int, formula: Int, water: Int)]
    let countData: [(date: Date, breastMilkCount: Int, formulaCount: Int, waterCount: Int)]
    
    var body: some View {
        VStack(spacing: 16) {
            FeedingVolumeCard(data: volumeData)
            FeedingCountCard(data: countData)
        }
    }
}

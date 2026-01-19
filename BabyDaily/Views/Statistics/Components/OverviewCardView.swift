import SwiftUI

// 单个概览卡片组件
struct OverviewCard: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                Text(trend)
                    .font(.system(size: 12))
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .padding(16)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 180)
    }
}

// 概览卡片组合视图
struct OverviewCardsView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // 喂养统计
                OverviewCard(title: "喂养总量", value: "800 ml", trend: "较昨日 ↑ 10%", isPositive: true)
                
                // 睡眠统计
                OverviewCard(title: "睡眠时长", value: "12 小时", trend: "较昨日 ↓ 5%", isPositive: false)
                
                // 换尿布统计
                OverviewCard(title: "换尿布次数", value: "8 次", trend: "较昨日 ↑ 2次", isPositive: true)
                
                // 成长统计卡片
                OverviewCard(title: "今日体重", value: "8.5 kg", trend: "较昨日 ↑ 0.1kg", isPositive: true)
            }
            .padding()
        }
    }
}
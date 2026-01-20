import SwiftUI

// 日期标题组件
struct DayHeader: View {
    let dayData: (day: Int, weekday: String, activities: [String])
    
    var body: some View {
        VStack {
            Text("\(dayData.day)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            Text(dayData.weekday)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(width: 50, height: 30)
        .border(Color(.systemGray5), width: 0.5)
    }
}

// 活动单元格组件
struct ActivityCell: View {
    let activity: String
    let day: Int
    let hour: Int
    let onSelect: ((day: Int, activity: String, hour: Int)) -> Void
    
    var body: some View {
        // 根据活动类型设置背景色
        let activityColor: Color
        switch activity {
        case "feeding":
            activityColor = Color.red.opacity(0.3)
        case "sleep":
            activityColor = Color.blue.opacity(0.3)
        case "play":
            activityColor = Color.green.opacity(0.3)
        case "change_diaper":
            activityColor = Color.yellow.opacity(0.3)
        case "bath":
            activityColor = Color.purple.opacity(0.3)
        default:
            activityColor = .secondary.opacity(0.3)
        }
        
        return Button(action: {
            onSelect((day: day, activity: activity, hour: hour))
        }) {
            Text(activity.localized)
                .font(.system(size: 8))
                .foregroundColor(.black)
                .frame(width: 30, height: 30)
                .background(activityColor)
                .border(Color(.systemGray3), width: 0.5)
        }
    }
}

// 单日活动行组件
struct DayActivityRow: View {
    let dayData: (day: Int, weekday: String, activities: [String])
    let onSelectActivity: ((day: Int, activity: String, hour: Int)) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 日期和星期
            DayHeader(dayData: dayData)
            
            // 活动单元格
            HStack(spacing: 0) {
                ForEach(dayData.activities.indices, id: \.self) { index in
                    ActivityCell(
                        activity: dayData.activities[index], 
                        day: dayData.day, 
                        hour: index,
                        onSelect: onSelectActivity
                    )
                }
            }
        }
    }
}

// 时间标签行组件
struct TimeLabelsRow: View {
    var body: some View {
        HStack(spacing: 0) {
            // 空白单元格
            Text("")
                .frame(width: 50, height: 30)
            
            // 小时标签
            ForEach(0..<24, id: \.self) { hour in
                Text("\(hour):00")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-45))
            }
        }
    }
}

// 活动网格组件
struct ActivityGrid: View {
    let data: [(day: Int, weekday: String, activities: [String])]
    let onSelectActivity: ((day: Int, activity: String, hour: Int)) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // 时间标签行
            TimeLabelsRow()
            
            // 每日活动网格
            ForEach(data.indices, id: \.self) { index in
                DayActivityRow(dayData: data[index], onSelectActivity: onSelectActivity)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}

// 活动图例组件
struct ActivityLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach([("feeding", Color.red), ("sleep", Color.blue), ("play", Color.green), ("change_diaper", Color.yellow), ("bath", Color.purple), ("other", .secondary)], id: \.0) { (activity, color) in
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(color.opacity(0.6))
                    Text(activity.localized)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// 活动详情组件
struct ActivityDetailView: View {
    let selectedActivity: (day: Int, activity: String, hour: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("activity_details".localized)
                .font(.system(size: 16, weight: .bold))
            Text(String(format: "date_format".localized, selectedActivity.day))
            Text(String(format: "time_format".localized, selectedActivity.hour))
            Text(String(format: "activity_format".localized, selectedActivity.activity.localized))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }
}

// 每日活动组合视图
struct DailyActivityView: View {
    let gridData: [(day: Int, weekday: String, activities: [String])]
    @Binding var selectedActivity: (day: Int, activity: String, hour: Int)?
    let timeRange: String
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            ChartTitleView(title: "daily_activity", timeRange: timeRange)
                .padding(.horizontal, 20)
            
            // 活动网格
            ActivityGrid(data: gridData, onSelectActivity: { activity in
                selectedActivity = activity
            })
            
            // 活动图例
            ActivityLegend()
            
            // 活动选择详情
            if let selectedActivity = selectedActivity {
                ActivityDetailView(selectedActivity: selectedActivity)
            }
        }
        .padding(.bottom, 20)
    }
}
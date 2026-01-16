import SwiftUI

struct RecordDetailView: View {
    let record: Record
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 记录基本信息
                HStack(spacing: 16) {
                    Text(record.icon)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.subCategory)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(record.category) · \(record.startTimestamp, format: Date.FormatStyle(date: .long, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // 记录内容
                VStack(alignment: .leading, spacing: 16) {
                    // 时间信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间")
                            .font(.headline)
                        
                        HStack {
                            Text("开始时间:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(record.startTimestamp, format: Date.FormatStyle(date: .long, time: .shortened))
                                .font(.subheadline)
                        }
                        
                        if let end = record.endTimestamp {
                            HStack {
                                Text("结束时间:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(end, format: Date.FormatStyle(date: .long, time: .shortened))
                                    .font(.subheadline)
                            }
                            
                            let duration = end.timeIntervalSince(record.startTimestamp)
                            let hours = Int(duration / 3600)
                            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                            HStack {
                                Text("持续时间:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(hours)小时\(minutes)分钟")
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 详细信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("详细信息")
                            .font(.headline)
                        
                        // 根据记录类型显示不同的详细信息
                        if record.subCategory == "亲喂" {
                            HStack {
                                Text("喂养侧:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(record.breastType ?? "双侧")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let name = record.name, !name.isEmpty {
                            HStack {
                                Text("名称:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(name)
                                    .font(.subheadline)
                            }
                        }
                        
                        if let value = record.value, let unit = record.unit {
                            HStack {
                                Text("用量:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(value)\(unit)")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let dayOrNight = record.dayOrNight {
                            HStack {
                                Text("时段:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(dayOrNight == "DAY" ? "白天" : "黑夜")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let acceptance = record.acceptance {
                            HStack {
                                Text("接受程度:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(acceptance == "LIKE" ? "喜欢" : acceptance == "NEUTRAL" ? "一般" : acceptance == "DISLIKE" ? "不喜欢" : "过敏")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let excrementStatus = record.excrementStatus {
                            HStack {
                                Text("排泄物类型:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(excrementStatus == "URINE" ? "小便" : excrementStatus == "STOOL" ? "大便" : "混合")
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 备注
                    if let remark = record.remark, !remark.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注")
                                .font(.headline)
                            Text(remark)
                                .font(.subheadline)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // 照片
                    if let photos = record.photos, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("照片")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(photos, id: \.self) {
                                    photoData in
                                    if let uiImage = UIImage(data: photoData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 150)
                                            .clipped()
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 导航到编辑页面
                }) {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}
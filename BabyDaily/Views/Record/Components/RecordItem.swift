//
//  RecordItem.swift
//  BabyDaily
//
// 单个记录项与记录照片预览组件。
//

import SwiftUI
import CoreData

// MARK: - 单个记录项组件
struct RecordItem: View {
    let record: Record
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: RecordDetailView(recordId: record.id)) {
            HStack(spacing: 12) {
                // 左侧：icon
                Text(record.icon)
                    .font(.title)
                    .frame(width: 40)
                
                // 中侧：名称、内容、时间、备注
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.subCategory?.localized ?? "")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(record.startTimestamp, format: Date.FormatStyle(time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 5) {
                        if let name = record.name, !name.isEmpty {
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(formatRecordContent(record))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let remark = record.remark, !remark.isEmpty {
                        Text(remark)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 右侧：图片列表
                RecordPhotosPreview(photos: record.photosArray)
                // 这里增加一个向右的箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                // 编辑记录
                onEdit()
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .tint(.accentColor)
            
            Button(role: .destructive) {
                // 删除记录
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
    
    // 格式化记录内容
    private func formatRecordContent(_ record: Record) -> String {
        guard let subCategory = record.subCategory else { return "" }
        
        switch subCategory {
        case "nursing", "sleep":
            var label = ""
            if let breastType = record.breastType {
                label =  breastType == "BOTH" ? "both_sides".localized : breastType == "LEFT" ? "left_side".localized : "right_side".localized
            }

            if let dayOrNight = record.dayOrNight {
               label = dayOrNight == "DAY" ? "daytime".localized + "☀️" : "night".localized + "🌙"
            }

            if let endTime = record.endTimestamp {
                return label + " " + localizedDuration(from: record.startTimestamp, to: endTime)
            } else {
                return label + " " + "in_progress".localized
            }
        case "pumping":
            var label = ""
            if let breastType = record.breastType {
                label =  breastType == "BOTH" ? "both_sides".localized : breastType == "LEFT" ? "left_side".localized : "right_side".localized
            }
            
            if let unit = record.unit {
                return label + " " + "\(record.value.smartDecimal) \(unit)"
            }
        case "breast_bottle", "formula", "water_intake":
            if let unit = record.unit {
                return "\(record.value.smartDecimal) \(unit)"
            }
        case "weight":
            if let unit = record.unit {
                return "\(record.value.smartDecimal) \(unit)"
            }
        case "height":
            if let unit = record.unit {
                return "\(record.value) \(unit)"
            }
        case "head":
            if let unit = record.unit {
                return "\(record.value.smartDecimal) \(unit)"
            }
        case "temperature":
            if let unit = record.unit {
                return "\(record.value.smartDecimal)°\(unit)"
            }
        case "diaper":
            if let status = record.excrementStatus {
                return status.lowercased().localized
            }
        case "solid_food":
            if let acceptance = record.acceptance {
                return acceptance.lowercased().localized
            }
        // case "medical_visit":
        //     if let name = record.name {
        //         return name
        //     }
        case "medication":
            if let unit = record.unit {
                return "(value) \(unit)"
            }
        case "supplement":
            if let unit = record.unit {
                return "(value) \(unit)"
            }
        // case "vaccination":
        //     if let name = record.name {
        //         return name
        //     }
        default:
            break
        }
        
        return ""
    }
}

// MARK: - 记录照片预览组件
struct RecordPhotosPreview: View {
    let photos: [Data]
    
    var body: some View {
        if !photos.isEmpty {
            HStack(alignment: .center, spacing: -26) {
                ForEach(photos.prefix(3).indices, id: \.self) {
                    index in
                    let photoData = photos[index]
                    if let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .cornerRadius(18)
                    }
                }
                
                if photos.count > 3 {
                    Text("+\(photos.count - 3)")
                        .font(.caption)
                        .padding(.leading, 30)
                }
            }
        }
    }
}

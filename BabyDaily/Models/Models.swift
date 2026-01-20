//
//  Models.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import Foundation
import SwiftData

@Model
final class Baby {
    var id: UUID = UUID()
    var name: String = ""
    var photo: Data?
    var birthday: Date = Date()
    var gender: String = "" // 男/女
    var weight: Double = 0.0
    var height: Double = 0.0
    var headCircumference: Double = 0.0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(id: UUID = UUID(), name: String, photo: Data? = nil, birthday: Date, gender: String, weight: Double, height: Double, headCircumference: Double, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.photo = photo
        self.birthday = birthday
        self.gender = gender
        self.weight = weight
        self.height = height
        self.headCircumference = headCircumference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class Record {
    public var id: UUID = UUID()
    public var babyId: UUID = UUID()
    public var icon: String = ""
    public var category: String = ""
    public var subCategory: String = ""
    public var startTimestamp: Date = Date()
    public var endTimestamp: Date?
    public var name: String?
    public var value: Double?
    public var unit: String?
    public var remark: String?
    public var photos: [Data]?
    public var breastType: String? // LEFT/RIGHT/BOTH
    public var dayOrNight: String? // DAY/NIGHT
    public var acceptance: String? // LIKE/NEUTRAL/DISLIKE/ALLERGY
    public var excrementStatus: String? // URINE/STOOL/MIXED
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    
    public init(id: UUID = UUID(), babyId: UUID, icon: String, category: String, subCategory: String, startTimestamp: Date, endTimestamp: Date? = nil, name: String? = nil, value: Double? = nil, unit: String? = nil, remark: String? = nil, photos: [Data]? = nil, breastType: String? = nil, dayOrNight: String? = nil, acceptance: String? = nil, excrementStatus: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.babyId = babyId
        self.icon = icon
        self.category = category
        self.subCategory = subCategory
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.name = name
        self.value = value
        self.unit = unit
        self.remark = remark
        self.photos = photos
        self.breastType = breastType
        self.dayOrNight = dayOrNight
        self.acceptance = acceptance
        self.excrementStatus = excrementStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// 用户设置模型，用于iCloud同步
@Model
final class UserSetting {
    var id: UUID = UUID()
    
    // 单位设置
    var temperatureUnit: String = "°C"
    var weightUnit: String = "kg"
    var lengthUnit: String = "cm"
    var volumeUnit: String = "ml"
    
    // 创建时间
    var createdAt: Date = Date()
    // 更新时间
    var updatedAt: Date = Date()
    
    init(id: UUID = UUID(), temperatureUnit: String = "°C", weightUnit: String = "kg", lengthUnit: String = "cm", volumeUnit: String = "ml", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.temperatureUnit = temperatureUnit
        self.weightUnit = weightUnit
        self.lengthUnit = lengthUnit
        self.volumeUnit = volumeUnit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// 生长数据结构体
struct GrowthData {
    let weight: Double
    let height: Double
    let headCircumference: Double
}

// Baby扩展，用于获取最新生长数据
extension Baby {
    func getLatestGrowthData(from records: [Record]) -> GrowthData {
        var latestWeight: Double?
        var latestHeight: Double?
        var latestHeadCircumference: Double?
        
        // 遍历记录，找到最新的体重、身高、头围记录
        for record in records {
            switch record.subCategory {
            case "weight":
                if latestWeight == nil, let weight = record.value {
                    latestWeight = weight
                }
            case "height":
                if latestHeight == nil, let height = record.value {
                    latestHeight = height
                }
            case "head":
                if latestHeadCircumference == nil, let headCircumference = record.value {
                    latestHeadCircumference = headCircumference
                }
            default:
                break
            }
            
            // 如果已经找到所有数据，提前退出循环
            if latestWeight != nil && latestHeight != nil && latestHeadCircumference != nil {
                break
            }
        }
        
        // 使用最新记录数据，如果没有则使用Baby信息中的数据
        return GrowthData(
            weight: latestWeight ?? self.weight,
            height: latestHeight ?? self.height,
            headCircumference: latestHeadCircumference ?? self.headCircumference
        )
    }
}
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
    var id: UUID
    var name: String
    var photo: Data?
    var birthday: Date
    var gender: String // 男/女
    var weight: Double
    var height: Double
    var headCircumference: Double
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, photo: Data? = nil, birthday: Date, gender: String, weight: Double, height: Double, headCircumference: Double, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.photo = photo
        self.birthday = birthday
        self.gender = gender
        self.weight = weight
        self.height = height
        self.headCircumference = headCircumference
        self.createdAt = createdAt
    }
}

@Model
public final class Record {
    public var id: UUID
    public var babyId: UUID
    public var icon: String
    public var category: String
    public var subCategory: String
    public var startTimestamp: Date
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
    
    public init(id: UUID = UUID(), babyId: UUID, icon: String, category: String, subCategory: String, startTimestamp: Date, endTimestamp: Date? = nil, name: String? = nil, value: Double? = nil, unit: String? = nil, remark: String? = nil, photos: [Data]? = nil, breastType: String? = nil, dayOrNight: String? = nil, acceptance: String? = nil, excrementStatus: String? = nil) {
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
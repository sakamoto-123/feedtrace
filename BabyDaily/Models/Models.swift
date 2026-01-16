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
final class Record {
    var id: UUID
    var babyId: UUID
    var icon: String
    var category: String
    var subCategory: String
    var startTimestamp: Date
    var endTimestamp: Date?
    var name: String?
    var value: Int?
    var unit: String?
    var remark: String?
    var photos: [Data]?
    var breastType: String? // LEFT/RIGHT/BOTH
    var dayOrNight: String? // DAY/NIGHT
    var acceptance: String? // LIKE/NEUTRAL/DISLIKE/ALLERGY
    var excrementStatus: String? // URINE/STOOL/MIXED
    
    init(id: UUID = UUID(), babyId: UUID, icon: String, category: String, subCategory: String, startTimestamp: Date, endTimestamp: Date? = nil, name: String? = nil, value: Int? = nil, unit: String? = nil, remark: String? = nil, photos: [Data]? = nil, breastType: String? = nil, dayOrNight: String? = nil, acceptance: String? = nil, excrementStatus: String? = nil) {
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
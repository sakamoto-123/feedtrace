//
//  Baby+CoreDataClass.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//
//

import Foundation
import CoreData

@objc(Baby)
public class Baby: NSManagedObject {
    
    // MARK: - Growth Data Calculation
    
    /// 获取最新的生长数据
    /// - Parameter records: 记录列表（通常是从 FetchRequest 获取的）
    /// - Returns: 包含体重、身高、头围的 GrowthData 结构体
    func getLatestGrowthData(from records: [Record]) -> GrowthData {
        var weight: Double = 0
        var height: Double = 0
        var headCircumference: Double = 0
        
        // 按时间降序排序
        let sortedRecords = records.sorted { $0.startTimestamp > $1.startTimestamp }
        
        // 查找最新的体重记录
        if let weightRecord = sortedRecords.first(where: { $0.subCategory == "weight" && $0.value > 0 }) {
            weight = weightRecord.value
        } else {
            // 如果没有记录，回退到 Baby 实体的初始值
            weight = self.weight
        }
        
        // 查找最新的身高记录
        if let heightRecord = sortedRecords.first(where: { $0.subCategory == "height" && $0.value > 0 }) {
            height = heightRecord.value
        } else {
            height = self.height
        }
        
        // 查找最新的头围记录
        if let headRecord = sortedRecords.first(where: { $0.subCategory == "head" && $0.value > 0 }) {
            headCircumference = headRecord.value
        } else {
            headCircumference = self.headCircumference
        }
        
        return GrowthData(weight: weight, height: height, headCircumference: headCircumference)
    }
}

/// 生长数据结构体
public struct GrowthData {
    public let weight: Double
    public let height: Double
    public let headCircumference: Double
}

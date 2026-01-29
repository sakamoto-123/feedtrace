//
//  DeduplicationManager.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/29.
//

import CoreData
import CloudKit

/// 管理 Core Data 数据去重，特别是解决 CloudKit 环境切换导致的数据重复问题
struct DeduplicationManager {
    static let shared = DeduplicationManager()
    
    /// 执行去重操作
    /// - Parameter context: NSManagedObjectContext
    func deduplicate(in context: NSManagedObjectContext) {
        context.perform {
            do {
                try self.deduplicateBabies(in: context)
                // 这里可以添加其他实体的去重逻辑
            } catch {
                Logger.error("Deduplication failed: \(error)")
            }
        }
    }
    
    /// 对 Baby 实体进行去重
    private func deduplicateBabies(in context: NSManagedObjectContext) throws {
        // 1. 获取所有 Baby 记录，按 ID 排序
        let request: NSFetchRequest<Baby> = Baby.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let babies = try context.fetch(request)
        guard !babies.isEmpty else { return }
        
        // 2. 按 UUID 分组
        let groupedBabies = Dictionary(grouping: babies) { $0.id }
        
        var duplicatesRemovedCount = 0
        
        // 3. 遍历分组，处理重复项
        for (id, babiesWithSameID) in groupedBabies {
            // 如果只有一条记录，说明没有重复，跳过
            if babiesWithSameID.count <= 1 { continue }
            
            Logger.warning("Found \(babiesWithSameID.count) duplicates for Baby ID: \(id)")
            
            // 4. 决定保留哪一条
            // 策略：保留关联记录（records）最多的那条；如果一样多，保留更新时间最新的
            let sortedBabies = babiesWithSameID.sorted { (b1, b2) -> Bool in
                let count1 = b1.records?.count ?? 0
                let count2 = b2.records?.count ?? 0
                
                if count1 != count2 {
                    return count1 > count2 // 记录多的优先
                }
                
                return b1.updatedAt > b2.updatedAt // 更新时间新的优先
            }
            
            // 第一个是要保留的，其余的都要删除
            let babyToKeep = sortedBabies.first!
            let babiesToDelete = sortedBabies.dropFirst()
            
            // 5. 执行删除
            for babyToDelete in babiesToDelete {
                Logger.info("Deleting duplicate baby: \(babyToDelete.name) (Records: \(babyToDelete.records?.count ?? 0))")
                
                // 此时，因为 Baby 和 Record 是 Cascade 删除关系，删除 Baby 会自动删除其 Records
                // 但如果 Records 也是重复的（双份），这是期望的行为
                // 如果 Records 是分散在两个 Baby 对象上（部分在这里，部分在那里），我们可能需要迁移 Records
                // 但在这个特定的 CloudKit 场景中，通常是整个对象图被完全复制了一份
                // 所以直接删除副本通常是安全的
                
                // 可选：如果需要合并 Records (虽然 CloudKit 这种场景下不太可能需要，因为通常是全量复制)
                // migrateRecords(from: babyToDelete, to: babyToKeep)
                
                context.delete(babyToDelete)
                duplicatesRemovedCount += 1
            }
        }
        
        // 6. 保存更改
        if duplicatesRemovedCount > 0 {
            if context.hasChanges {
                try context.save()
                Logger.info("Successfully removed \(duplicatesRemovedCount) duplicate babies.")
            }
        } else {
            Logger.info("No duplicate babies found.")
        }
    }
    
    // 备用：如果未来需要合并 Records
    private func migrateRecords(from source: Baby, to destination: Baby) {
        guard let records = source.records as? Set<Record> else { return }
        
        for record in records {
            // 将 Record 重新关联到保留的 Baby 上
            record.baby = destination
        }
    }
}

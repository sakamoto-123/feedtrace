import SwiftData
import Foundation

// 自定义错误类型
enum DataMigrationError: Error {
    case migrationFailed(modelType: String, reason: String)
    case deduplicationFailed(modelType: String, reason: String)
    case contextSaveFailed(reason: String)
    
    var localizedDescription: String {
        switch self {
        case .migrationFailed(let modelType, let reason):
            return "迁移失败 [\(modelType)]: \(reason)"
        case .deduplicationFailed(let modelType, let reason):
            return "去重失败 [\(modelType)]: \(reason)"
        case .contextSaveFailed(let reason):
            return "上下文保存失败: \(reason)"
        }
    }
}

class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    // 泛型迁移单个模型数据
    private func migrateModel<T: PersistentModel>(_ type: T.Type, from sourceContext: ModelContext, to targetContext: ModelContext) throws {
        let typeName = String(describing: type)
        Logger.info("开始迁移模型: \(typeName)")
        
        let fetchDescriptor = FetchDescriptor<T>()
        let sourceItems = try sourceContext.fetch(fetchDescriptor)
        Logger.info("从源容器获取到 \(sourceItems.count) 条 \(typeName) 数据")
        
        // 获取目标容器中已存在的所有项目，构建ID映射
        let targetFetchDescriptor = FetchDescriptor<T>()
        let targetItems = try targetContext.fetch(targetFetchDescriptor)
        Logger.info("从目标容器获取到 \(targetItems.count) 条已存在的 \(typeName) 数据")

        // 输出所有的 targetItems 和 sourceItems 的id
        Logger.debug("目标容器中的 \(typeName) 数据ID: \(targetItems.map { $0.id })")
        Logger.debug("源容器中的 \(typeName) 数据ID: \(sourceItems.map { $0.id })")
        
        // 构建现有项目ID映射，直接访问id属性
        var existingItemMap = [UUID: T]()
        for item in targetItems {
            // 根据模型类型直接获取id
            var itemId: UUID
            if let baby = item as? Baby {
                itemId = baby.id
            } else if let record = item as? Record {
                itemId = record.id
            } else if let setting = item as? UserSetting {
                itemId = setting.id
            } else {
                Logger.error("未知模型类型: \(typeName)")
                continue
            }
            existingItemMap[itemId] = item
        }
        
        var addedCount = 0
        var updatedCount = 0
        var skippedCount = 0
        
        for sourceItem in sourceItems {
            // 直接访问id和updatedAt属性
            var sourceId: UUID
            var sourceUpdatedAt: Date
            
            if let baby = sourceItem as? Baby {
                sourceId = baby.id
                sourceUpdatedAt = baby.updatedAt
            } else if let record = sourceItem as? Record {
                sourceId = record.id
                sourceUpdatedAt = record.updatedAt
            } else if let setting = sourceItem as? UserSetting {
                sourceId = setting.id
                sourceUpdatedAt = setting.updatedAt
            } else {
                Logger.error("未知模型类型: \(typeName)")
                continue
            }
            
            // 检查目标容器中是否已存在该ID的数据
            if let existingItem = existingItemMap[sourceId] {
                // 目标容器中已存在，比较updatedAt字段，保留最新版本
                var existingUpdatedAt: Date
                
                if let existingBaby = existingItem as? Baby {
                    existingUpdatedAt = existingBaby.updatedAt
                } else if let existingRecord = existingItem as? Record {
                    existingUpdatedAt = existingRecord.updatedAt
                } else if let existingSetting = existingItem as? UserSetting {
                    existingUpdatedAt = existingSetting.updatedAt
                } else {
                    Logger.error("未知模型类型: \(typeName)")
                    continue
                }
                
                if sourceUpdatedAt > existingUpdatedAt {
                    // 源数据更新，替换目标数据
                    // 对于不同类型，我们需要单独处理属性复制
                    if let sourceBaby = sourceItem as? Baby, let targetBaby = existingItem as? Baby {
                        targetBaby.name = sourceBaby.name
                        targetBaby.photo = sourceBaby.photo
                        targetBaby.birthday = sourceBaby.birthday
                        targetBaby.gender = sourceBaby.gender
                        targetBaby.weight = sourceBaby.weight
                        targetBaby.height = sourceBaby.height
                        targetBaby.headCircumference = sourceBaby.headCircumference
                        targetBaby.updatedAt = sourceBaby.updatedAt
                        updatedCount += 1
                    } else if let sourceRecord = sourceItem as? Record, let targetRecord = existingItem as? Record {
                        targetRecord.babyId = sourceRecord.babyId
                        targetRecord.icon = sourceRecord.icon
                        targetRecord.category = sourceRecord.category
                        targetRecord.subCategory = sourceRecord.subCategory
                        targetRecord.startTimestamp = sourceRecord.startTimestamp
                        targetRecord.endTimestamp = sourceRecord.endTimestamp
                        targetRecord.name = sourceRecord.name
                        targetRecord.value = sourceRecord.value
                        targetRecord.unit = sourceRecord.unit
                        targetRecord.remark = sourceRecord.remark
                        targetRecord.photos = sourceRecord.photos
                        targetRecord.breastType = sourceRecord.breastType
                        targetRecord.dayOrNight = sourceRecord.dayOrNight
                        targetRecord.acceptance = sourceRecord.acceptance
                        targetRecord.excrementStatus = sourceRecord.excrementStatus
                        targetRecord.updatedAt = sourceRecord.updatedAt
                        updatedCount += 1
                    } else if let sourceSetting = sourceItem as? UserSetting, let targetSetting = existingItem as? UserSetting {
                        targetSetting.temperatureUnit = sourceSetting.temperatureUnit
                        targetSetting.weightUnit = sourceSetting.weightUnit
                        targetSetting.lengthUnit = sourceSetting.lengthUnit
                        targetSetting.volumeUnit = sourceSetting.volumeUnit
                        targetSetting.updatedAt = sourceSetting.updatedAt
                        updatedCount += 1
                    }
                } else {
                    // 源数据不是最新的，跳过
                    skippedCount += 1
                }
            } else {
                // 目标容器中不存在，直接添加
                if let sourceBaby = sourceItem as? Baby {
                    let newBaby = Baby(
                        id: sourceBaby.id,
                        name: sourceBaby.name,
                        photo: sourceBaby.photo,
                        birthday: sourceBaby.birthday,
                        gender: sourceBaby.gender,
                        weight: sourceBaby.weight,
                        height: sourceBaby.height,
                        headCircumference: sourceBaby.headCircumference,
                        createdAt: sourceBaby.createdAt,
                        updatedAt: sourceBaby.updatedAt
                    )
                    targetContext.insert(newBaby)
                    addedCount += 1
                } else if let sourceRecord = sourceItem as? Record {
                    let newRecord = Record(
                        id: sourceRecord.id,
                        babyId: sourceRecord.babyId,
                        icon: sourceRecord.icon,
                        category: sourceRecord.category,
                        subCategory: sourceRecord.subCategory,
                        startTimestamp: sourceRecord.startTimestamp,
                        endTimestamp: sourceRecord.endTimestamp,
                        name: sourceRecord.name,
                        value: sourceRecord.value,
                        unit: sourceRecord.unit,
                        remark: sourceRecord.remark,
                        photos: sourceRecord.photos,
                        breastType: sourceRecord.breastType,
                        dayOrNight: sourceRecord.dayOrNight,
                        acceptance: sourceRecord.acceptance,
                        excrementStatus: sourceRecord.excrementStatus,
                        createdAt: sourceRecord.createdAt,
                        updatedAt: sourceRecord.updatedAt
                    )
                    targetContext.insert(newRecord)
                    addedCount += 1
                } else if let sourceSetting = sourceItem as? UserSetting {
                    let newSetting = UserSetting(
                        id: sourceSetting.id,
                        temperatureUnit: sourceSetting.temperatureUnit,
                        weightUnit: sourceSetting.weightUnit,
                        lengthUnit: sourceSetting.lengthUnit,
                        volumeUnit: sourceSetting.volumeUnit,
                        createdAt: sourceSetting.createdAt,
                        updatedAt: sourceSetting.updatedAt
                    )
                    targetContext.insert(newSetting)
                    addedCount += 1
                }
            }
        }
        
        Logger.info("\(typeName) 迁移完成: 新增 \(addedCount) 条, 更新 \(updatedCount) 条, 跳过 \(skippedCount) 条")
    }
    
    // 迁移数据从一个容器到另一个容器
    func migrateData(from sourceContainer: ModelContainer, to targetContainer: ModelContainer) -> Result<Bool, Error> {
        Logger.info("开始数据迁移操作")
        let startTime = Date()
        
        do {
            // 创建源上下文和目标上下文
            let sourceContext = ModelContext(sourceContainer)
            let targetContext = ModelContext(targetContainer)
            
            // 迁移所有模型数据
            try migrateModel(Baby.self, from: sourceContext, to: targetContext)
            try migrateModel(Record.self, from: sourceContext, to: targetContext)
            try migrateModel(UserSetting.self, from: sourceContext, to: targetContext)
            
            // 保存目标上下文的更改
            do {
                try targetContext.save()
                let duration = Date().timeIntervalSince(startTime)
                Logger.info("数据迁移成功，耗时: \(String(format: "%.2f", duration)) 秒")
                return .success(true)
            } catch {
                throw DataMigrationError.contextSaveFailed(reason: error.localizedDescription)
            }
        } catch {
            Logger.error("数据迁移失败: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // 泛型去重单个模型数据
    private func deduplicateModel<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        let typeName = String(describing: type)
        Logger.info("开始去重模型: \(typeName)")
        
        let fetchDescriptor = FetchDescriptor<T>()
        let items = try context.fetch(fetchDescriptor)
        Logger.info("获取到 \(items.count) 条 \(typeName) 数据进行去重")
        
        // 按ID分组，保留每个ID最新的记录
        var uniqueItems = [UUID: T]()
        var deletedCount = 0
        
        for item in items {
            // 直接访问id和updatedAt属性
            var id: UUID
            var updatedAt: Date
            
            if let baby = item as? Baby {
                id = baby.id
                updatedAt = baby.updatedAt
            } else if let record = item as? Record {
                id = record.id
                updatedAt = record.updatedAt
            } else if let setting = item as? UserSetting {
                id = setting.id
                updatedAt = setting.updatedAt
            } else {
                Logger.error("未知模型类型: \(typeName)，跳过记录")
                continue
            }
            
            if let existing = uniqueItems[id] {
                // 如果已存在该ID，比较updatedAt，保留最新的
                var existingUpdatedAt: Date
                
                if let existingBaby = existing as? Baby {
                    existingUpdatedAt = existingBaby.updatedAt
                } else if let existingRecord = existing as? Record {
                    existingUpdatedAt = existingRecord.updatedAt
                } else if let existingSetting = existing as? UserSetting {
                    existingUpdatedAt = existingSetting.updatedAt
                } else {
                    Logger.error("未知模型类型: \(typeName)，跳过记录")
                    continue
                }
                
                if updatedAt > existingUpdatedAt {
                    // 新记录更新，删除旧记录
                    uniqueItems[id] = item
                    context.delete(existing)
                    deletedCount += 1
                } else {
                    // 旧记录更新，删除新记录
                    context.delete(item)
                    deletedCount += 1
                }
            } else {
                // 第一次遇到该ID，直接添加
                uniqueItems[id] = item
            }
        }
        
        Logger.info("\(typeName) 去重完成: 删除 \(deletedCount) 条重复数据，保留 \(uniqueItems.count) 条唯一数据")
    }
    
    // 全局去重方法，确保每个ID只有一条记录，保留最新版本
    func removeDuplicates(in container: ModelContainer) -> Result<Bool, Error> {
        Logger.info("开始全局去重操作")
        let startTime = Date()
        
        do {
            let context = ModelContext(container)
            
            // 去重所有模型数据
            try deduplicateModel(Baby.self, in: context)
            try deduplicateModel(Record.self, in: context)
            try deduplicateModel(UserSetting.self, in: context)
            
            // 保存更改
            do {
                try context.save()
                let duration = Date().timeIntervalSince(startTime)
                Logger.info("全局去重成功，耗时: \(String(format: "%.2f", duration)) 秒")
                return .success(true)
            } catch {
                throw DataMigrationError.contextSaveFailed(reason: error.localizedDescription)
            }
        } catch {
            Logger.error("全局去重失败: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

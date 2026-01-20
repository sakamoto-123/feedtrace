import SwiftData
import Foundation

class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    // 节流相关
    private let migrationThrottleInterval: TimeInterval = 60 // 60秒迁移节流间隔
    private let deduplicationThrottleInterval: TimeInterval = 30 // 30秒去重节流间隔
    private var lastMigrationTimestamp: Date = Date.distantPast
    private var lastDeduplicationTimestamp: Date = Date.distantPast
    
    private init() {}
    
    // 迁移数据从一个容器到另一个容器
    func migrateData(from sourceContainer: ModelContainer, to targetContainer: ModelContainer) async {
        // 迁移节流检查
        let now = Date()
        if now.timeIntervalSince(lastMigrationTimestamp) < migrationThrottleInterval {
            print("Migration throttled: \(now.timeIntervalSince(lastMigrationTimestamp))s since last migration")
            return
        }
        
        do {
            // 创建源上下文和目标上下文
            let sourceContext = ModelContext(sourceContainer)
            let targetContext = ModelContext(targetContainer)
            
            // 迁移Baby数据
            let babyFetchDescriptor = FetchDescriptor<Baby>()
            let babies = try sourceContext.fetch(babyFetchDescriptor)
            
            // 优化：只执行一次fetch，然后在内存中匹配
            let allTargetBabiesFetchDescriptor = FetchDescriptor<Baby>()
            let allTargetBabies = try targetContext.fetch(allTargetBabiesFetchDescriptor)
            let existingBabyMap = Dictionary(uniqueKeysWithValues: allTargetBabies.map { ($0.id, $0) })
            
            for baby in babies {
                if let existingBaby = existingBabyMap[baby.id] {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if baby.updatedAt > existingBaby.updatedAt {
                        // 源数据更新，替换目标数据
                        existingBaby.name = baby.name
                        existingBaby.photo = baby.photo
                        existingBaby.birthday = baby.birthday
                        existingBaby.gender = baby.gender
                        existingBaby.weight = baby.weight
                        existingBaby.height = baby.height
                        existingBaby.headCircumference = baby.headCircumference
                        existingBaby.updatedAt = baby.updatedAt
                    }
                } else {
                    // 目标容器中不存在，直接添加
                    let newBaby = Baby(
                        id: baby.id,
                        name: baby.name,
                        photo: baby.photo,
                        birthday: baby.birthday,
                        gender: baby.gender,
                        weight: baby.weight,
                        height: baby.height,
                        headCircumference: baby.headCircumference,
                        createdAt: baby.createdAt,
                        updatedAt: baby.updatedAt
                    )
                    targetContext.insert(newBaby)
                }
            }
            
            // 迁移Record数据
            let recordFetchDescriptor = FetchDescriptor<Record>()
            let records = try sourceContext.fetch(recordFetchDescriptor)
            
            // 优化：只执行一次fetch，然后在内存中匹配
            let allTargetRecordsFetchDescriptor = FetchDescriptor<Record>()
            let allTargetRecords = try targetContext.fetch(allTargetRecordsFetchDescriptor)
            let existingRecordMap = Dictionary(uniqueKeysWithValues: allTargetRecords.map { ($0.id, $0) })
            
            for record in records {
                if let existingRecord = existingRecordMap[record.id] {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if record.updatedAt > existingRecord.updatedAt {
                        // 源数据更新，替换目标数据
                        existingRecord.babyId = record.babyId
                        existingRecord.icon = record.icon
                        existingRecord.category = record.category
                        existingRecord.subCategory = record.subCategory
                        existingRecord.startTimestamp = record.startTimestamp
                        existingRecord.endTimestamp = record.endTimestamp
                        existingRecord.name = record.name
                        existingRecord.value = record.value
                        existingRecord.unit = record.unit
                        existingRecord.remark = record.remark
                        existingRecord.photos = record.photos
                        existingRecord.breastType = record.breastType
                        existingRecord.dayOrNight = record.dayOrNight
                        existingRecord.acceptance = record.acceptance
                        existingRecord.excrementStatus = record.excrementStatus
                        existingRecord.updatedAt = record.updatedAt
                    }
                } else {
                    // 目标容器中不存在，直接添加
                    let newRecord = Record(
                        id: record.id,
                        babyId: record.babyId,
                        icon: record.icon,
                        category: record.category,
                        subCategory: record.subCategory,
                        startTimestamp: record.startTimestamp,
                        endTimestamp: record.endTimestamp,
                        name: record.name,
                        value: record.value,
                        unit: record.unit,
                        remark: record.remark,
                        photos: record.photos,
                        breastType: record.breastType,
                        dayOrNight: record.dayOrNight,
                        acceptance: record.acceptance,
                        excrementStatus: record.excrementStatus,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt
                    )
                    targetContext.insert(newRecord)
                }
            }
            
            // 迁移UserSetting数据
            let userSettingFetchDescriptor = FetchDescriptor<UserSetting>()
            let userSettings = try sourceContext.fetch(userSettingFetchDescriptor)
            
            // 优化：只执行一次fetch，然后在内存中匹配
            let allTargetSettingsFetchDescriptor = FetchDescriptor<UserSetting>()
            let allTargetSettings = try targetContext.fetch(allTargetSettingsFetchDescriptor)
            let existingSettingMap = Dictionary(uniqueKeysWithValues: allTargetSettings.map { ($0.id, $0) })
            
            for setting in userSettings {
                if let existingSetting = existingSettingMap[setting.id] {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if setting.updatedAt > existingSetting.updatedAt {
                        // 源数据更新，替换目标数据
                        existingSetting.language = setting.language
                        existingSetting.themeMode = setting.themeMode
                        existingSetting.themeColor = setting.themeColor
                        existingSetting.temperatureUnit = setting.temperatureUnit
                        existingSetting.weightUnit = setting.weightUnit
                        existingSetting.lengthUnit = setting.lengthUnit
                        existingSetting.volumeUnit = setting.volumeUnit
                        existingSetting.selectedBabyId = setting.selectedBabyId
                        existingSetting.updatedAt = setting.updatedAt
                    }
                } else {
                    // 目标容器中不存在，直接添加
                    let newSetting = UserSetting(
                        id: setting.id,
                        language: setting.language,
                        themeMode: setting.themeMode,
                        themeColor: setting.themeColor,
                        temperatureUnit: setting.temperatureUnit,
                        weightUnit: setting.weightUnit,
                        lengthUnit: setting.lengthUnit,
                        volumeUnit: setting.volumeUnit,
                        selectedBabyId: setting.selectedBabyId,
                        createdAt: setting.createdAt,
                        updatedAt: setting.updatedAt
                    )
                    targetContext.insert(newSetting)
                }
            }
            
            // 保存目标上下文的更改
            try targetContext.save()
            // 更新最后迁移时间
            lastMigrationTimestamp = Date()
            print("数据迁移成功")
        } catch {
            print("数据迁移失败: \(error)")
        }
    }
    
    // 全局去重方法，确保每个ID只有一条记录，保留最新版本
    func removeDuplicates(in container: ModelContainer) async {
        // 去重节流检查
        let now = Date()
        if now.timeIntervalSince(lastDeduplicationTimestamp) < deduplicationThrottleInterval {
            print("Deduplication throttled: \(now.timeIntervalSince(lastDeduplicationTimestamp))s since last deduplication")
            return
        }
        
        do {
            let context = ModelContext(container)
            
            // 去重Baby数据
            let babyFetchDescriptor = FetchDescriptor<Baby>()
            let babies = try context.fetch(babyFetchDescriptor)
            
            // 按ID分组，保留每个ID最新的记录
            var uniqueBabies = [UUID: Baby]()
            for baby in babies {
                if let existing = uniqueBabies[baby.id] {
                    // 如果已存在该ID，比较updatedAt，保留最新的
                    if baby.updatedAt > existing.updatedAt {
                        // 新记录更新，删除旧记录
                        uniqueBabies[baby.id] = baby
                        context.delete(existing)
                    } else {
                        // 旧记录更新，删除新记录
                        context.delete(baby)
                    }
                } else {
                    // 第一次遇到该ID，直接添加
                    uniqueBabies[baby.id] = baby
                }
            }
            
            // 去重Record数据
            let recordFetchDescriptor = FetchDescriptor<Record>()
            let records = try context.fetch(recordFetchDescriptor)
            
            var uniqueRecords = [UUID: Record]()
            for record in records {
                if let existing = uniqueRecords[record.id] {
                    if record.updatedAt > existing.updatedAt {
                        uniqueRecords[record.id] = record
                        context.delete(existing)
                    } else {
                        context.delete(record)
                    }
                } else {
                    uniqueRecords[record.id] = record
                }
            }
            
            // 去重UserSetting数据
            let userSettingFetchDescriptor = FetchDescriptor<UserSetting>()
            let userSettings = try context.fetch(userSettingFetchDescriptor)
            
            var uniqueSettings = [UUID: UserSetting]()
            for setting in userSettings {
                if let existing = uniqueSettings[setting.id] {
                    if setting.updatedAt > existing.updatedAt {
                        uniqueSettings[setting.id] = setting
                        context.delete(existing)
                    } else {
                        context.delete(setting)
                    }
                } else {
                    uniqueSettings[setting.id] = setting
                }
            }
            
            // 保存更改
            try context.save()
            // 更新最后去重时间
            lastDeduplicationTimestamp = Date()
            print("去重成功")
        } catch {
            print("去重失败: \(error)")
        }
    }
}
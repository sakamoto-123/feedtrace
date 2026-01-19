import SwiftData
import Foundation

class DataMigrationManager {
    static let shared = DataMigrationManager()
    private init() {}
    
    // 迁移数据从一个容器到另一个容器
    func migrateData(from sourceContainer: ModelContainer, to targetContainer: ModelContainer) async {
        do {
            // 创建源上下文和目标上下文
            let sourceContext = ModelContext(sourceContainer)
            let targetContext = ModelContext(targetContainer)
            
            // 迁移Baby数据
            let babyFetchDescriptor = FetchDescriptor<Baby>()
            let babies = try sourceContext.fetch(babyFetchDescriptor)
            for baby in babies {
                // 获取目标容器中所有Baby，然后在内存中过滤
                let allTargetBabiesFetchDescriptor = FetchDescriptor<Baby>()
                let allTargetBabies = try targetContext.fetch(allTargetBabiesFetchDescriptor)
                let existingBaby = allTargetBabies.first { $0.id == baby.id }
                
                if existingBaby == nil {
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
                } else {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if baby.updatedAt > existingBaby!.updatedAt {
                        // 源数据更新，替换目标数据
                        existingBaby!.name = baby.name
                        existingBaby!.photo = baby.photo
                        existingBaby!.birthday = baby.birthday
                        existingBaby!.gender = baby.gender
                        existingBaby!.weight = baby.weight
                        existingBaby!.height = baby.height
                        existingBaby!.headCircumference = baby.headCircumference
                        existingBaby!.updatedAt = baby.updatedAt
                    }
                }
            }
            
            // 迁移Record数据
            let recordFetchDescriptor = FetchDescriptor<Record>()
            let records = try sourceContext.fetch(recordFetchDescriptor)
            for record in records {
                // 获取目标容器中所有Record，然后在内存中过滤
                let allTargetRecordsFetchDescriptor = FetchDescriptor<Record>()
                let allTargetRecords = try targetContext.fetch(allTargetRecordsFetchDescriptor)
                let existingRecord = allTargetRecords.first { $0.id == record.id }
                
                if existingRecord == nil {
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
                } else {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if record.updatedAt > existingRecord!.updatedAt {
                        // 源数据更新，替换目标数据
                        existingRecord!.babyId = record.babyId
                        existingRecord!.icon = record.icon
                        existingRecord!.category = record.category
                        existingRecord!.subCategory = record.subCategory
                        existingRecord!.startTimestamp = record.startTimestamp
                        existingRecord!.endTimestamp = record.endTimestamp
                        existingRecord!.name = record.name
                        existingRecord!.value = record.value
                        existingRecord!.unit = record.unit
                        existingRecord!.remark = record.remark
                        existingRecord!.photos = record.photos
                        existingRecord!.breastType = record.breastType
                        existingRecord!.dayOrNight = record.dayOrNight
                        existingRecord!.acceptance = record.acceptance
                        existingRecord!.excrementStatus = record.excrementStatus
                        existingRecord!.updatedAt = record.updatedAt
                    }
                }
            }
            
            // 迁移UserSetting数据
            let userSettingFetchDescriptor = FetchDescriptor<UserSetting>()
            let userSettings = try sourceContext.fetch(userSettingFetchDescriptor)
            for setting in userSettings {
                // 获取目标容器中所有UserSetting，然后在内存中过滤
                let allTargetSettingsFetchDescriptor = FetchDescriptor<UserSetting>()
                let allTargetSettings = try targetContext.fetch(allTargetSettingsFetchDescriptor)
                let existingSetting = allTargetSettings.first { $0.id == setting.id }
                
                if existingSetting == nil {
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
                        createdAt: setting.createdAt,
                        updatedAt: setting.updatedAt
                    )
                    targetContext.insert(newSetting)
                } else {
                    // 目标容器中已存在，比较updatedAt字段，保留最新版本
                    if setting.updatedAt > existingSetting!.updatedAt {
                        // 源数据更新，替换目标数据
                        existingSetting!.language = setting.language
                        existingSetting!.themeMode = setting.themeMode
                        existingSetting!.themeColor = setting.themeColor
                        existingSetting!.temperatureUnit = setting.temperatureUnit
                        existingSetting!.weightUnit = setting.weightUnit
                        existingSetting!.lengthUnit = setting.lengthUnit
                        existingSetting!.volumeUnit = setting.volumeUnit
                        existingSetting!.updatedAt = setting.updatedAt
                    }
                }
            }
            
            // 保存目标上下文的更改
            try targetContext.save()
            print("数据迁移成功")
        } catch {
            print("数据迁移失败: \(error)")
        }
    }
}
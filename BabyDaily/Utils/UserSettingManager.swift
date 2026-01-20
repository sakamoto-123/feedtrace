//
//  UserSettingManager.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/19.
//

import SwiftUI
import SwiftData
import Combine

// 用户设置管理器，用于处理UserSetting的创建、访问和迁移
class UserSettingManager: ObservableObject {
    // 单例模式
    static let shared = UserSettingManager()
    
    // 共享的ModelContext
    private var modelContext: ModelContext?
    
    // UserSetting实例
    @Published var userSetting: UserSetting?
    
    // 初始化
    private init() {}
    
    // 设置ModelContext
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateUserSetting()
    }
    
    // 加载或创建UserSetting实例
    private func loadOrCreateUserSetting() {
        guard let modelContext = modelContext else { return }
        
        do {
            // 尝试获取现有的UserSetting
            let fetchDescriptor = FetchDescriptor<UserSetting>()
            let settings = try modelContext.fetch(fetchDescriptor)
            
            if let existingSetting = settings.first {
                // 使用现有设置
                userSetting = existingSetting
                // 同步到管理类
                syncToManagers(existingSetting)
            } else {
                // 创建新的UserSetting，从UserDefaults迁移数据
                let newSetting = createUserSettingFromDefaults()
                modelContext.insert(newSetting)
                try modelContext.save()
                userSetting = newSetting
            }
        } catch {
            Logger.error("Failed to load or create UserSetting: \(error)")
            // 从UserDefaults获取最新设置，而不是使用默认值
            let newSetting = createUserSettingFromDefaults()
            modelContext.insert(newSetting)
            do {
                try modelContext.save()
                userSetting = newSetting
            } catch {
                Logger.error("Failed to save UserSetting from defaults: \(error)")
            }
        }
    }
    
    // 从UserDefaults创建UserSetting
    private func createUserSettingFromDefaults() -> UserSetting {
        // 单位设置
        let temperatureUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "°C"
        let weightUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"
        let lengthUnit = UserDefaults.standard.string(forKey: "lengthUnit") ?? "cm"
        let volumeUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? "ml"
        
        // 创建并返回UserSetting
        return UserSetting(
            temperatureUnit: temperatureUnit,
            weightUnit: weightUnit,
            lengthUnit: lengthUnit,
            volumeUnit: volumeUnit
        )
    }
    
    // 同步UserSetting到各个管理类
    private func syncToManagers(_ setting: UserSetting) {
        // 只同步单位设置到UnitManager
        if let temperatureUnit = TemperatureUnit(rawValue: setting.temperatureUnit) {
            UnitManager.shared.temperatureUnit = temperatureUnit
        }
        if let weightUnit = WeightUnit(rawValue: setting.weightUnit) {
            UnitManager.shared.weightUnit = weightUnit
        }
        if let lengthUnit = LengthUnit(rawValue: setting.lengthUnit) {
            UnitManager.shared.lengthUnit = lengthUnit
        }
        if let volumeUnit = VolumeUnit(rawValue: setting.volumeUnit) {
            UnitManager.shared.volumeUnit = volumeUnit
        }
    }
    
    // 更新UserSetting
    func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) {
        guard let modelContext = modelContext, var userSetting = userSetting else { return }
        
        do {
            updateBlock(userSetting)
            userSetting.updatedAt = Date()
            
            try modelContext.save()
            self.userSetting = userSetting
        } catch {
            Logger.error("Failed to update UserSetting: \(error)")
        }
    }
    
    // 获取UserSetting实例
    func getUserSetting() -> UserSetting? {
        return userSetting
    }
    
    // 从UserDefaults同步获取选中的宝宝ID，用于快速加载
    func getSelectedBabyIdFromDefaults() -> UUID? {
        if let babyIdString = UserDefaults.standard.string(forKey: "selectedBabyId"), let babyId = UUID(uuidString: babyIdString) {
            return babyId
        }
        return nil
    }
    
    // 设置选中的宝宝ID
    func setSelectedBabyId(_ babyId: UUID?) {
        // 只更新UserDefaults，用于快速加载
        if let babyId = babyId {
            UserDefaults.standard.set(babyId.uuidString, forKey: "selectedBabyId")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedBabyId")
        }
    }
}

// 扩展UnitManager，使用UserSettingManager
fileprivate extension UnitManager {
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        await UserSettingManager.shared.updateUserSetting(updateBlock)
    }
}

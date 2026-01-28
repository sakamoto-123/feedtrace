//
//  UserSettingManager.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/19.
//

import SwiftUI
import CoreData
import Combine

// 用户设置管理器，用于处理UserSetting的创建、访问和迁移
class UserSettingManager: ObservableObject {
    // 单例模式
    static let shared = UserSettingManager()
    
    // 共享的 ManagedObjectContext
    private var viewContext: NSManagedObjectContext?
    
    // UserSetting实例
    @Published var userSetting: UserSetting?
    
    // 初始化
    private init() {}
    
    // 设置 ManagedObjectContext
    func setup(modelContext: NSManagedObjectContext) {
        self.viewContext = modelContext
        loadOrCreateUserSetting()
    }
    
    // 加载或创建UserSetting实例
    private func loadOrCreateUserSetting() {
        guard let context = viewContext else { return }
        
        context.perform {
            do {
                // 尝试获取现有的UserSetting
                let request: NSFetchRequest<UserSetting> = UserSetting.fetchRequest()
                request.fetchLimit = 1
                let settings = try context.fetch(request)
                
                if let existingSetting = settings.first {
                    // 使用现有设置
                    DispatchQueue.main.async {
                        self.userSetting = existingSetting
                        // 同步到管理类
                        self.syncToManagers(existingSetting)
                    }
                } else {
                    // 创建新的UserSetting，从UserDefaults迁移数据
                    let newSetting = self.createUserSettingFromDefaults(context: context)
                    try context.save()
                    
                    DispatchQueue.main.async {
                        self.userSetting = newSetting
                    }
                }
            } catch {
                Logger.error("Failed to load or create UserSetting: \(error)")
                // 从UserDefaults获取最新设置，而不是使用默认值
                let newSetting = self.createUserSettingFromDefaults(context: context)
                do {
                    try context.save()
                    DispatchQueue.main.async {
                        self.userSetting = newSetting
                    }
                } catch {
                    Logger.error("Failed to save UserSetting from defaults: \(error)")
                }
            }
        }
    }
    
    // 从UserDefaults创建UserSetting
    private func createUserSettingFromDefaults(context: NSManagedObjectContext) -> UserSetting {
        // 单位设置
        let temperatureUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "°C"
        let weightUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"
        let lengthUnit = UserDefaults.standard.string(forKey: "lengthUnit") ?? "cm"
        let volumeUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? "ml"
        
        // 创建并返回UserSetting
        let setting = UserSetting(context: context)
        setting.id = UUID()
        setting.createdAt = Date()
        setting.updatedAt = Date()
        setting.temperatureUnit = temperatureUnit
        setting.weightUnit = weightUnit
        setting.lengthUnit = lengthUnit
        setting.volumeUnit = volumeUnit
        
        return setting
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
        guard let context = viewContext, let userSetting = userSetting else { return }
        
        context.perform {
            updateBlock(userSetting)
            userSetting.updatedAt = Date()
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    self.userSetting = userSetting
                }
            } catch {
                Logger.error("Failed to update UserSetting: \(error)")
            }
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

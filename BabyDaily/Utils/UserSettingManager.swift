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
    
    // 新增：指示UserSetting是否已经加载完成
    @Published var isLoaded = false
    
    // 初始化
    private init() {}
    
    // 设置ModelContext
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadOrCreateUserSetting()
        }
    }
    
    // 加载或创建UserSetting实例
    @MainActor
    private func loadOrCreateUserSetting() async {
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
            print("Failed to load or create UserSetting: \(error)")
            // 创建默认设置
            let defaultSetting = UserSetting()
            modelContext.insert(defaultSetting)
            do {
                try modelContext.save()
                userSetting = defaultSetting
            } catch {
                print("Failed to save default UserSetting: \(error)")
            }
        }
        
        // 设置isLoaded为true，表示加载完成
        isLoaded = true
        
        // 将selectedBabyId同步到UserDefaults，确保下次启动时能快速加载
        if let selectedBabyId = userSetting?.selectedBabyId {
            UserDefaults.standard.set(selectedBabyId.uuidString, forKey: "selectedBabyId")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedBabyId")
        }
    }
    
    // 从UserDefaults创建UserSetting
    private func createUserSettingFromDefaults() -> UserSetting {
        // 语言设置
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        
        // 主题设置
        let themeMode = UserDefaults.standard.string(forKey: "selectedThemeMode") ?? "system"
        let themeColor = UserDefaults.standard.string(forKey: "selectedThemeColor") ?? "blue"
        
        // 单位设置
        let temperatureUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "°C"
        let weightUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? "kg"
        let lengthUnit = UserDefaults.standard.string(forKey: "lengthUnit") ?? "cm"
        let volumeUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? "ml"
        
        // 创建并返回UserSetting
        return UserSetting(
            language: language,
            themeMode: themeMode,
            themeColor: themeColor,
            temperatureUnit: temperatureUnit,
            weightUnit: weightUnit,
            lengthUnit: lengthUnit,
            volumeUnit: volumeUnit,
            selectedBabyId: nil
        )
    }
    
    // 同步UserSetting到各个管理类
    private func syncToManagers(_ setting: UserSetting) {
        // 同步到LanguageManager
        if let language = AppLanguage(rawValue: setting.language) {
            LanguageManager.shared.selectedLanguage = language
        }
        
        // 同步到ThemeManager
        if let themeMode = ThemeMode(rawValue: setting.themeMode) {
            ThemeManager.shared.selectedThemeMode = themeMode
        }
        if let themeColor = ThemeColor(rawValue: setting.themeColor) {
            ThemeManager.shared.selectedThemeColor = themeColor
        }
        
        // 同步到UnitManager
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
    @MainActor
    func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        guard let modelContext = modelContext, var userSetting = userSetting else { return }
        
        do {
            updateBlock(userSetting)
            userSetting.updatedAt = Date()
            try modelContext.save()
            self.userSetting = userSetting
        } catch {
            print("Failed to update UserSetting: \(error)")
        }
    }
    
    // 获取UserSetting实例
    func getUserSetting() -> UserSetting? {
        return userSetting
    }
    
    // 获取选中的宝宝ID
    func getSelectedBabyId() -> UUID? {
        // 安全访问，避免访问已销毁的实例
        do {
            // 尝试访问属性，如果实例已销毁，会抛出错误
            guard let setting = userSetting else { return nil }
            // 这里使用try?来捕获可能的销毁错误
            let result = try? setting.selectedBabyId
            if result == nil {
                // 如果访问失败，说明实例已销毁，重新加载
                Task {
                    await loadOrCreateUserSetting()
                }
            }
            return result
        } catch {
            // 如果发生错误，重新加载
            Task {
                await loadOrCreateUserSetting()
            }
            return nil
        }
    }
    
    // 从UserDefaults同步获取选中的宝宝ID，用于快速加载
    func getSelectedBabyIdFromDefaults() -> UUID? {
        if let babyIdString = UserDefaults.standard.string(forKey: "selectedBabyId"), let babyId = UUID(uuidString: babyIdString) {
            return babyId
        }
        return nil
    }
    
    // 设置选中的宝宝ID
    @MainActor
    func setSelectedBabyId(_ babyId: UUID?) async {
        // 更新SwiftData中的UserSetting
        await updateUserSetting { setting in
            setting.selectedBabyId = babyId
        }
        
        // 同时更新UserDefaults，用于快速加载
        if let babyId = babyId {
            UserDefaults.standard.set(babyId.uuidString, forKey: "selectedBabyId")
        } else {
            UserDefaults.standard.removeObject(forKey: "selectedBabyId")
        }
    }
}

// 扩展ThemeManager，使用UserSettingManager
fileprivate extension ThemeManager {
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        await UserSettingManager.shared.updateUserSetting(updateBlock)
    }
}

// 扩展LanguageManager，使用UserSettingManager
fileprivate extension LanguageManager {
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        await UserSettingManager.shared.updateUserSetting(updateBlock)
    }
}

// 扩展UnitManager，使用UserSettingManager
fileprivate extension UnitManager {
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) async {
        await UserSettingManager.shared.updateUserSetting(updateBlock)
    }
}

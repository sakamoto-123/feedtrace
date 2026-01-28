import Foundation
import Combine

// 温度单位枚举
enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    var id: Self { self }
}

// 重量单位枚举
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg = "kg"
    case lb = "lb"
    case oz = "oz"
    
    var id: Self { self }
}

// 长度单位枚举
enum LengthUnit: String, CaseIterable, Identifiable {
    case cm = "cm"
    case inch = "in"
    case foot = "ft"
    
    var id: Self { self }
}

// 体积单位枚举
enum VolumeUnit: String, CaseIterable, Identifiable {
    case ml = "ml"
    case oz = "oz"
    
    var id: Self { self }
}

// 单位管理类
class UnitManager: ObservableObject {
    // 单例模式
    static let shared = UnitManager()
    
    // UserDefaults 键名
    private let temperatureUnitKey = "temperatureUnit"
    private let weightUnitKey = "weightUnit"
    private let lengthUnitKey = "lengthUnit"
    private let volumeUnitKey = "volumeUnit"
    
    // MARK: - 存储属性
    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            // 更新UserDefaults和UserSetting
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: temperatureUnitKey)
            updateUserSetting { [self] setting in
                setting.temperatureUnit = self.temperatureUnit.rawValue
            }
        }
    }
    
    @Published var weightUnit: WeightUnit {
        didSet {
            // 更新UserDefaults和UserSetting
            UserDefaults.standard.set(weightUnit.rawValue, forKey: weightUnitKey)
            updateUserSetting { [self] setting in
                setting.weightUnit = self.weightUnit.rawValue
            }
        }
    }
    
    @Published var lengthUnit: LengthUnit {
        didSet {
            // 更新UserDefaults和UserSetting
            UserDefaults.standard.set(lengthUnit.rawValue, forKey: lengthUnitKey)
            updateUserSetting { [self] setting in
                setting.lengthUnit = self.lengthUnit.rawValue
            }
        }
    }
    
    @Published var volumeUnit: VolumeUnit {
        didSet {
            // 更新UserDefaults和UserSetting
            UserDefaults.standard.set(volumeUnit.rawValue, forKey: volumeUnitKey)
            updateUserSetting { [self] setting in
                setting.volumeUnit = self.volumeUnit.rawValue
            }
        }
    }
    
    // 初始化方法
    private init() {
        // 从 UserDefaults 加载初始值
        self.temperatureUnit = Self.loadTemperatureUnit()
        self.weightUnit = Self.loadWeightUnit()
        self.lengthUnit = Self.loadLengthUnit()
        self.volumeUnit = Self.loadVolumeUnit()
    }
    
    // MARK: - 加载方法
    private static func loadTemperatureUnit() -> TemperatureUnit {
        let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? TemperatureUnit.celsius.rawValue
        return TemperatureUnit(rawValue: savedUnit) ?? .celsius
    }
    
    private static func loadWeightUnit() -> WeightUnit {
        let savedUnit = UserDefaults.standard.string(forKey: "weightUnit") ?? WeightUnit.kg.rawValue
        return WeightUnit(rawValue: savedUnit) ?? .kg
    }
    
    private static func loadLengthUnit() -> LengthUnit {
        let savedUnit = UserDefaults.standard.string(forKey: "lengthUnit") ?? LengthUnit.cm.rawValue
        return LengthUnit(rawValue: savedUnit) ?? .cm
    }
    
    private static func loadVolumeUnit() -> VolumeUnit {
        let savedUnit = UserDefaults.standard.string(forKey: "volumeUnit") ?? VolumeUnit.ml.rawValue
        return VolumeUnit(rawValue: savedUnit) ?? .ml
    }
    
    // 获取UserSetting实例
    private func getUserSetting() -> UserSetting? {
        // 通过单例访问UserSettingManager获取UserSetting
        return UserSettingManager.shared.getUserSetting()
    }
    
    // 更新UserSetting实例
    private func updateUserSetting(_ updateBlock: @escaping (UserSetting) -> Void) {
        // 使用UserSettingManager的API更新UserSetting
        UserSettingManager.shared.updateUserSetting(updateBlock)
    }
}

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
    @Published var temperatureUnit: TemperatureUnit
    @Published var weightUnit: WeightUnit
    @Published var lengthUnit: LengthUnit
    @Published var volumeUnit: VolumeUnit
    
    // 初始化方法
    private init() {
        // 从 UserDefaults 加载初始值
        self.temperatureUnit = Self.loadTemperatureUnit()
        self.weightUnit = Self.loadWeightUnit()
        self.lengthUnit = Self.loadLengthUnit()
        self.volumeUnit = Self.loadVolumeUnit()
        
        // 监听属性变化，保存到 UserDefaults
        setupObservers()
    }
    
    // 设置观察者
    private func setupObservers() {
        $temperatureUnit.sink { [weak self] newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: self?.temperatureUnitKey ?? "")
        }
        .store(in: &cancellables)
        
        $weightUnit.sink { [weak self] newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: self?.weightUnitKey ?? "")
        }
        .store(in: &cancellables)
        
        $lengthUnit.sink { [weak self] newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: self?.lengthUnitKey ?? "")
        }
        .store(in: &cancellables)
        
        $volumeUnit.sink { [weak self] newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: self?.volumeUnitKey ?? "")
        }
        .store(in: &cancellables)
    }
    
    // 存储取消令牌
    private var cancellables = Set<AnyCancellable>()
    
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
}

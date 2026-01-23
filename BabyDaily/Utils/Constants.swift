import SwiftUI

// 项目常量结构体
struct Constants {
    // 全局圆角半径常量
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 40

    static let noDetailCategories: Set<String> = [
        "bath", "walking", "playing",
        "first_tooth", "first_walk", "first_sit", "first_crawl", "first_roll", "first_word"
    ]

    static let milestoneCategories: Set<String> = [
    "first_tooth", "first_walk", "first_sit", "first_crawl", "first_roll", "first_word"
    ]

    static let hasEndTimeCategories: Set<String> = [
        "sleep", 
        "nursing", 
        "pumping"
    ]
    
    // 所有操作分类
    static let allCategorys: [String: [(icon: String, name: String, color: Color)]] = [
        "feeding_category": [
            (icon: "🤱", name: "nursing", color: Color.fromHex("#ffc76b")),
            (icon: "🍼", name: "breast_bottle", color: Color.fromHex("#ffc76b")),
            (icon: "🍼", name: "formula", color: Color.fromHex("#b0a4e3")),
            (icon: "🥣", name: "solid_food", color: Color.fromHex("#b7dbff")),
            // (icon: "💧", name: "water_intake", color: Color.fromHex("#aad9f2"))
        ],
        "activity_category": [
            (icon: "😴", name: "sleep", color: Color.fromHex("#87a8c3")),
            (icon: "🩲", name: "diaper", color: Color.fromHex("#955539")),
            (icon: "🛁", name: "bath", color: Color.fromHex("#4b9be1")),
            // (icon: "🥛", name: "pumping", color: Color.fromHex("#cea6e3"))
        ],  
        "health_category": [
            (icon: "🟡", name: "jaundice", color: Color.fromHex("#b7d07a")),
            (icon: "🦴", name: "supplement", color: Color.fromHex("#6cb09e")),
            (icon: "💉", name: "vaccination", color: Color.fromHex("#55bb8a")),
            (icon: "🌡️", name: "temperature", color: Color.fromHex("#ad6598")),
            (icon: "💊", name: "medication", color: Color.fromHex("#b2bbbe")),
            (icon: "🏥", name: "medical_visit", color: Color.fromHex("#EBCDA8")),
        ],
        "growth_category": [
            (icon: "📏", name: "height", color: Color.fromHex("#88ada6")),
            (icon: "⚖️", name: "weight", color: Color.fromHex("#b9dec9")),
            (icon: "👶", name: "head", color: Color.fromHex("#84ae64"))
        ],
        "milestone_category": [
            (icon: "🦷", name: "first_tooth", color: Color.fromHex("#ffb658")),
            (icon: "🧘", name: "first_sit", color: Color.fromHex("#ff9066")),
            (icon: "🐢", name: "first_crawl", color: Color.fromHex("#b19f8f")),
            (icon: "🤸‍♀️", name: "first_roll", color: Color.fromHex("#a7a8bd")),
            (icon: "💬", name: "first_word", color: Color.fromHex("#ae88c3")),
            (icon: "🚶", name: "first_walk", color: Color.fromHex("#ffbeba"))
        ]
    ]

    // 所有操作分类 - 保持原始顺序
    static var allCategorysByOrder: [(category: String, actions: [(icon: String, name: String, color: Color)])] = [
        (category: "feeding_category", actions: Constants.allCategorys["feeding_category"] ?? []),
        (category: "activity_category", actions: Constants.allCategorys["activity_category"] ?? []),
        (category: "growth_category", actions: Constants.allCategorys["growth_category"] ?? []),
        (category: "health_category", actions: Constants.allCategorys["health_category"] ?? []),
        (category: "milestone_category", actions: Constants.allCategorys["milestone_category"] ?? [])
    ]
    
    static let LengthUnits = ["cm", "in", "ft"]
    static let WeightUnits = ["kg", "lb", "oz"]
    static let VolumeUnits = ["ml", "oz"]
    static let TemperatureUnits = ["°C", "°F"]

    static let OtherUnits: [String] = ["tablet", "piece", "cup", "bowl"]
    
    // 单位常量
    struct Units {
        // 长度单位
        struct Length {
            static let cm = "cm"
            static let inch = "in"
            static let foot = "ft"
        }
        
        // 容量单位
        struct Volume {
            static let ml = "ml"
            static let oz = "oz"
        }
        
        // 重量单位
        struct Weight {
            static let kg = "kg"
            static let lb = "lb"
            static let oz = "oz"
        }
        
        // 温度单位
        struct Temperature {
            static let celsius = "°C"
            static let fahrenheit = "°F"
        }

        // 其他单位
        struct Other {
            static let none = ""
        }
    }
}
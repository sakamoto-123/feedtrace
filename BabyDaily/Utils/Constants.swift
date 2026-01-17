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
        // "pumping"
    ]
    
    // 所有操作分类
    static let allCategorys: [String: [(icon: String, name: String, color: Color)]] = [
        "feeding_category": [
            (icon: "🤱", name: "nursing", color: Color.fromHex("#ffc76b")),
            (icon: "🍼", name: "breast_bottle", color: Color.fromHex("#ffc76b")),
            (icon: "🍼", name: "formula", color: Color.fromHex("#eef7f2")),
            (icon: "🥣", name: "solid_food", color: Color.fromHex("#b7dbff")),
            (icon: "💧", name: "water_intake", color: Color.fromHex("#aad9f2"))
        ],
        "activity_category": [
            (icon: "😴", name: "sleep", color: Color.fromHex("#87a8c3")),
            (icon: "🧻", name: "diaper", color: Color.fromHex("#ffe5d6")),
            (icon: "🛁", name: "bath", color: Color.fromHex("#4b9be1")),
            (icon: "🚶", name: "walking", color: Color.fromHex("#ffbeba")),
            (icon: "🧸", name: "playing", color: Color.fromHex("#c5e6b6")),
            (icon: "🥛", name: "pumping", color: Color.fromHex("#cea6e3"))
        ],
        "growth_category": [
            (icon: "📏", name: "height", color: Color.fromHex("#d1ffff")),
            (icon: "⚖️", name: "weight", color: Color.fromHex("#b9dec9")),
            (icon: "📐", name: "head", color: Color.fromHex("#84ae64"))
        ],    
        "health_category": [
            (icon: "🟡", name: "jaundice", color: Color.fromHex("#b7d07a")),
            (icon: "🏥", name: "medical_visit", color: Color.fromHex("#EBCDA8")),
            (icon: "💉", name: "vaccination", color: Color.fromHex("#55bb8a")),
            (icon: "🌡️", name: "temperature", color: Color.fromHex("#ad6598")),
            (icon: "💊", name: "medication", color: Color.fromHex("#b2bbbe")),
            (icon: "🦴", name: "supplement", color: Color.fromHex("#6cb09e"))
        ],
        "milestone_category": [
            (icon: "🦷", name: "first_tooth", color: Color.fromHex("#ffb658")),
            (icon: "🪑", name: "first_sit", color: Color.fromHex("#ff9066")),
            (icon: "🐢", name: "first_crawl", color: Color.fromHex("#b19f8f")),
            (icon: "🔄", name: "first_roll", color: Color.fromHex("#a7a8bd")),
            (icon: "🗣️", name: "first_word", color: Color.fromHex("#ae88c3")),
            (icon: "🚶", name: "first_walk", color: Color.fromHex("#ffbeba"))
        ]
    ]
}
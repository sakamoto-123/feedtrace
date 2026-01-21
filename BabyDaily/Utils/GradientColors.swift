//
//  GradientColors.swift
//  BabyDaily
//
//  渐变颜色工具类
//  提供应用中使用的渐变颜色定义
//

import SwiftUI

/// 渐变颜色工具
struct GradientColors {
    /// 会员主题渐变（橙色/金色）
    static let premiumGradient = LinearGradient(
        colors: [
            Color(hex: "#FF8C42"), // 橙色
            Color(hex: "#FFB347"), // 金色
            Color(hex: "#FFA500")  // 橙金色
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 按钮渐变（橙色/红色）
    static let buttonGradient = LinearGradient(
        colors: [
            Color(hex: "#FF6B35"), // 橙红色
            Color(hex: "#FF8C42"), // 橙色
            Color(hex: "#FF6B6B")  // 红色
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 会员主题颜色（纯色，用于文本）
    static let premiumColor = Color(hex: "#FF8C42")
    
    /// 按钮背景颜色
    static let buttonColor = Color(hex: "#FF6B35")
}

/// 渐变视图修饰符
extension View {
    /// 应用会员主题渐变
    func premiumGradient() -> some View {
        self.foregroundStyle(GradientColors.premiumGradient)
    }
    
    /// 应用按钮渐变背景
    func buttonGradientBackground() -> some View {
        self.background(GradientColors.buttonGradient)
    }
}

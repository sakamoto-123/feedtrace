//
//  ChartUtils.swift
//  BabyDaily
//
//  Created on 2026/1/17.
//

import Foundation
import SwiftUI

/// 根据时间范围创建日期域
func makeDateDomain(
    range: String,
    calendar: Calendar = .current,
    now: Date = Date()
) -> ClosedRange<Date> {

    let dayCount: Int
    switch range {
    case "7_days":
        dayCount = 7
    case "14_days":
        dayCount = 14
    case "30_days":
        dayCount = 30
    case "90_days":
        dayCount = 90
    case "12_months":
        dayCount = 365
    default:
        dayCount = 7
    }

    let end = calendar.startOfDay(for: now)
    guard let startBase = calendar.date(
        byAdding: .day,
        value: -(dayCount - 1),
        to: end
    ),
    let upperBoundBase = calendar.date(byAdding: .day, value: 1, to: end)
    else {
        // 如果计算失败，返回当天到第二天
        return end...calendar.date(byAdding: .day, value: 1, to: end)!
    }
    
    // 为柱状图添加缓冲空间：开始日期提前 0.5 天，结束日期延后 0.5 天
    // 这样可以避免柱状图超出图表边界
    let start = startBase.addingTimeInterval(-8 * 60 * 60) // 减去 12 小时
    let upperBound = upperBoundBase.addingTimeInterval(8 * 60 * 60) // 加上 12 小时

    // 注意：end 要加 1 天，才能完整显示最后一天
    // 同时添加 0.5 天的缓冲空间，确保柱状图不会超出边界
    return start...upperBound
}

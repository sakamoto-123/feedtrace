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
    guard let start = calendar.date(
        byAdding: .day,
        value: -(dayCount - 1),
        to: end
    ),
    let upperBound = calendar.date(byAdding: .day, value: 1, to: end)
    else {
        // 如果计算失败，返回当天到第二天
        return end...calendar.date(byAdding: .day, value: 1, to: end)!
    }

    // 注意：end 要加 1 天，才能完整显示最后一天
    return start...upperBound
}

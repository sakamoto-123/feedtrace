//
//  CloudKitConfig.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/20.
//

import Foundation

/// CloudKit配置常量
struct CloudKitConfig {
    /// CloudKit容器ID
    static let containerIdentifier = "iCloud.cn.iizhi.BabyDaily"
    
    /// CloudStore名称
    static let cloudStoreName = "CloudStore"
    
    /// LocalStore名称
    static let localStoreName = "LocalStore"
    
    /// 最小iCloud可用空间要求（100MB）
    static let minRequiredSpace: Int64 = 100 * 1024 * 1024
    
    /// iCloud同步等待时间（3秒）
    static let syncWaitTime: TimeInterval = 3.0
}

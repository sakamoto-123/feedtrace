//
//  CloudSyncManager.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/19.
//

import Foundation
import SwiftData
import CloudKit
import SwiftUI
import Combine

// 同步状态枚举
enum SyncStatus {
    case idle
    case syncing
    case completed
    case error(Error)
}

class CloudSyncManager: ObservableObject {
    // 单例模式
    static let shared = CloudSyncManager()
    
    // 同步状态
    @Published var syncStatus: SyncStatus = .idle
    
    // 初始化
    private init() {}
    
    // 手动触发同步
    func syncData(modelContext: ModelContext, isICloudSyncEnabled: Bool) async {
        // 只有在开启iCloud同步时才执行同步操作
        guard isICloudSyncEnabled else {
            syncStatus = .completed
            return
        }
        
        syncStatus = .syncing
        
        do {
            // 保存所有未保存的更改
            try modelContext.save()
            
            // 触发CloudKit同步
            try fetchLatestDataFromiCloud(modelContext: modelContext)
            
            syncStatus = .completed
        } catch {
            print("Sync error: \(error)")
            syncStatus = .error(error)
        }
    }
    
    // 从iCloud获取最新数据
    public func fetchLatestDataFromiCloud(modelContext: ModelContext) throws {
        // 使用SwiftData的自动同步机制
        // 对于CloudKit配置的ModelContainer，SwiftData会自动处理数据同步
        // 这里可以添加额外的同步逻辑，如果需要的话
        
        // 示例：获取所有Baby记录，触发同步
        let babyFetchDescriptor = FetchDescriptor<Baby>()
        let _ = try modelContext.fetch(babyFetchDescriptor)
        
        // 示例：获取所有Record记录，触发同步
        let recordFetchDescriptor = FetchDescriptor<Record>()
        let _ = try modelContext.fetch(recordFetchDescriptor)
        
        // 示例：获取所有UserSetting记录，触发同步
        let userSettingFetchDescriptor = FetchDescriptor<UserSetting>()
        let _ = try modelContext.fetch(userSettingFetchDescriptor)
    }
    
    // 检查iCloud可用性
    func checkiCloudAvailability() async -> Bool {
        guard let ubiquityContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return false
        }
        return ubiquityContainerURL.path.contains("iCloud")
    }
    
    // 获取同步状态文本
    func getSyncStatusText() -> String {
        switch syncStatus {
        case .idle:
            return "icloud_sync_idle".localized
        case .syncing:
            return "icloud_sync_syncing".localized
        case .completed:
            return "icloud_sync_completed".localized
        case .error(let error):
            return "icloud_sync_error".localized + ": \(error.localizedDescription)"
        }
    }
    
    // 获取同步状态颜色
    func getSyncStatusColor() -> SwiftUI.Color {
        switch syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}
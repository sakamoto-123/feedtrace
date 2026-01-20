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

// iCloud状态枚举
enum iCloudStatus {
    case notLoggedIn      // 未登录iCloud
    case insufficientSpace // 存储空间不足
    case available         // 可用
    
    // 获取状态描述
    var description: String {
        switch self {
        case .notLoggedIn:
            return "未登录iCloud"
        case .insufficientSpace:
            return "iCloud存储空间不足"
        case .available:
            return "iCloud可用"
        }
    }
}

// 同步状态枚举
enum SyncStatus {
    case idle
    case syncing
    case completed
    case error(Error)
    
    // 获取状态描述
    var description: String {
        switch self {
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
    
    // 获取状态颜色
    var color: Color {
        switch self {
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

class CloudSyncManager: ObservableObject {
    // 单例模式
    static let shared = CloudSyncManager()
    
    // 同步状态
    @Published var syncStatus: SyncStatus = .idle
    
    // iCloud状态
    @Published var icloudStatus: iCloudStatus = .available
    
    // 初始化
    private init() {}
    
    // MARK: - ModelContainer Management
    
    /// 创建ModelContainer
    static func createModelContainer(isICloudSyncEnabled: Bool) -> ModelContainer {
        let schema = CloudKitConfig.schema
        
        do {
            if isICloudSyncEnabled {
                // CloudKit同步配置
                let cloudConfiguration = ModelConfiguration(
                    CloudKitConfig.cloudStoreName, // 使用不同的名称区分存储
                    schema: schema,
                    cloudKitDatabase: .private(CloudKitConfig.containerIdentifier)
                )
                let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])
                Logger.info("Created CloudKit ModelContainer")
                return container
            } else {
                // 本地存储配置 - 明确指定不使用CloudKit，使用独立的文件URL
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let localStoreURL = documentsDirectory.appendingPathComponent("\(CloudKitConfig.localStoreName).sqlite")
                
                let localConfiguration = ModelConfiguration(
                    CloudKitConfig.localStoreName, // 使用不同的名称区分存储
                    schema: schema,
                    url: localStoreURL
                )
                let container = try ModelContainer(for: schema, configurations: [localConfiguration])
                Logger.info("Created Local ModelContainer at URL: \(localStoreURL)")
                return container
            }
        } catch {
            fatalError("[CloudSync] Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - iCloud Status Check
    
    /// 检查iCloud状态
    func checkiCloudStatus() -> iCloudStatus {
        // 调试信息：打印当前设备类型
        #if targetEnvironment(simulator)
        Logger.debug("Running on simulator - using mock iCloud status")
        // 模拟器上，直接返回可用状态，因为模拟器的iCloud容器访问可能不可靠
        let mockStatus = iCloudStatus.available
        updateICloudStatus(mockStatus)
        return mockStatus
        #else
        // 真机上，使用真实的iCloud状态检查
        // 检查是否登录iCloud
        guard let ubiquityContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            Logger.warning("iCloud not logged in")
            let status = iCloudStatus.notLoggedIn
            updateICloudStatus(status)
            return status
        }
        
        Logger.debug("iCloud logged in, checking storage")
        
        do {
            // 检查可用存储空间
            let resourceValues = try ubiquityContainerURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage {
                Logger.debug("iCloud available capacity: \(availableCapacity)")
                let status = availableCapacity > CloudKitConfig.minRequiredSpace ? iCloudStatus.available : iCloudStatus.insufficientSpace
                updateICloudStatus(status)
                return status
            }
        } catch {
            Logger.error("Error checking iCloud storage: \(error)")
        }
        
        Logger.warning("iCloud storage check failed, defaulting to available")
        // 如果存储检查失败，默认返回可用状态
        let defaultStatus = iCloudStatus.available
        updateICloudStatus(defaultStatus)
        return defaultStatus
        #endif
    }
    
    // MARK: - Data Sync
    
    /// 手动触发同步
    func syncData(modelContext: ModelContext, isICloudSyncEnabled: Bool) {
        // 只有在开启iCloud同步时才执行同步操作
        guard isICloudSyncEnabled else {
            updateSyncStatus(.completed)
            return
        }
        
        updateSyncStatus(.syncing)
        
        do {
            // 1. 先执行本地数据去重
            let container = modelContext.container
            DataMigrationManager.shared.removeDuplicates(in: container)
            
            // 2. 保存去重后的更改
            try modelContext.save()
            
            updateSyncStatus(.completed)
        } catch {
            Logger.error("Sync error: \(error)")
            updateSyncStatus(.error(error))
        }
    }
    
    // MARK: - State Management
    
    /// 获取同步状态文本
    func getSyncStatusText() -> String {
        return syncStatus.description
    }
    
    /// 获取同步状态颜色
    func getSyncStatusColor() -> Color {
        return syncStatus.color
    }
    
    /// 更新同步状态
    private func updateSyncStatus(_ status: SyncStatus) {
        self.syncStatus = status
    }
    
    /// 更新iCloud状态
    private func updateICloudStatus(_ status: iCloudStatus) {
        self.icloudStatus = status
    }
}
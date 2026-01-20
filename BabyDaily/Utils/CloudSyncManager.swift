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
}

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
    
    // 同步节流相关
    private let syncThrottleInterval: TimeInterval = 30 // 30秒节流间隔
    private var lastSyncTimestamp: Date = Date.distantPast
    
    // 初始化
    private init() {}
    
    // 检查iCloud状态
    func checkiCloudStatus() async -> iCloudStatus {
        // 调试信息：打印当前设备类型
        #if targetEnvironment(simulator)
        print("Running on simulator - using mock iCloud status")
        // 模拟器上，直接返回可用状态，因为模拟器的iCloud容器访问可能不可靠
        return .available
        #else
        // 真机上，使用真实的iCloud状态检查
        // 检查是否登录iCloud
        guard let ubiquityContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            print("iCloud not logged in")
            return .notLoggedIn
        }
        
        print("iCloud logged in, checking storage")
        
        do {
            // 检查可用存储空间
            let resourceValues = try ubiquityContainerURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage {
                // 检查可用空间是否大于100MB
                let requiredSpace: Int64 = 100 * 1024 * 1024 // 100MB
                print("iCloud available capacity: \(availableCapacity)")
                return availableCapacity > requiredSpace ? .available : .insufficientSpace
            }
        } catch {
            print("Error checking iCloud storage: \(error)")
        }
        
        print("iCloud storage check failed, defaulting to available")
        // 如果存储检查失败，默认返回可用状态
        return .available
        #endif
    }
    
    // 手动触发同步
    func syncData(modelContext: ModelContext, isICloudSyncEnabled: Bool) async {
        // 只有在开启iCloud同步时才执行同步操作
        guard isICloudSyncEnabled else {
            await updateSyncStatus(.completed)
            return
        }
        
        // 同步节流检查
        let now = Date()
        if now.timeIntervalSince(lastSyncTimestamp) < syncThrottleInterval {
            print("Sync throttled: \(now.timeIntervalSince(lastSyncTimestamp))s since last sync")
            await updateSyncStatus(.completed)
            return
        }
        
        await updateSyncStatus(.syncing)
        
        do {
            // 1. 先执行本地数据去重（在后台）
            await Task.detached { [modelContext] in
                // 获取modelContext的容器（非可选类型）
                let container = modelContext.container
                await DataMigrationManager.shared.removeDuplicates(in: container)
            }.value
            
            // 2. 保存去重后的更改
            try await Task.detached { [modelContext] in
                try modelContext.save()
            }.value
            
            // 3. 触发CloudKit同步
            await Task.detached { [modelContext] in
                // 直接调用，不需要通过shared实例
                do {
                    try self.fetchLatestDataFromiCloud(modelContext: modelContext)
                } catch {
                    print("Fetch error in detached task: \(error)")
                }
            }.value
            
            // 更新最后同步时间
            lastSyncTimestamp = Date()
            await updateSyncStatus(.completed)
        } catch {
            print("Sync error: \(error)")
            await updateSyncStatus(.error(error))
        }
    }
    
    // 从iCloud获取最新数据
    public func fetchLatestDataFromiCloud(modelContext: ModelContext) throws {
        // 使用SwiftData的自动同步机制
        // 对于CloudKit配置的ModelContainer，SwiftData会自动处理数据同步
        // 移除不必要的fetch操作，减少资源消耗
        // SwiftData会在后台自动处理CloudKit同步，无需手动触发
        
        // 只保存当前上下文的更改，确保本地数据已保存
        try modelContext.save()
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
    
    // 在主线程更新同步状态
    private func updateSyncStatus(_ status: SyncStatus) async {
        await MainActor.run {
            self.syncStatus = status
        }
    }
}
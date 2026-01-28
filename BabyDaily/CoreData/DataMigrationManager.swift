//
//  DataMigrationManager.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import Foundation
import CoreData

/// 数据迁移管理器：处理从 SwiftData 到 Core Data 的文件级迁移
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    /// 执行迁移逻辑
    /// - Parameter targetName: 目标 Core Data 存储文件名 (例如 "BabyDaily_CoreData.sqlite")
    func migrateSwiftDataToCoreData(targetName: String) {
        let fileManager = FileManager.default
        
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        
        // SwiftData 默认存储路径
        let sourceURL = appSupportURL.appendingPathComponent("default.store")
        
        // 目标 Core Data 存储路径
        let targetURL = appSupportURL.appendingPathComponent(targetName)
        
        // 检查源文件是否存在
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            Logger.info("Migration: No SwiftData store found at \(sourceURL.path). Skipping.")
            return
        }
        
        // 检查目标文件是否已存在 (如果已存在，说明已经迁移过或已经在使用新库)
        if fileManager.fileExists(atPath: targetURL.path) {
            Logger.info("Migration: Target store already exists at \(targetURL.path). Skipping.")
            return
        }
        
        // 执行文件移动 (包括 .wal 和 .shm 辅助文件)
        do {
            Logger.info("Migration: Migrating SwiftData store to Core Data...")
            
            // 1. 移动主文件
            try fileManager.moveItem(at: sourceURL, to: targetURL)
            Logger.info("Migration: Moved .sqlite file")
            
            // 2. 移动 .wal 文件 (Write-Ahead Log)
            let sourceWal = sourceURL.appendingPathExtension("wal")
            let targetWal = targetURL.appendingPathExtension("wal")
            if fileManager.fileExists(atPath: sourceWal.path) {
                try fileManager.moveItem(at: sourceWal, to: targetWal)
                Logger.info("Migration: Moved .wal file")
            }
            
            // 3. 移动 .shm 文件 (Shared Memory)
            let sourceShm = sourceURL.appendingPathExtension("shm")
            let targetShm = targetURL.appendingPathExtension("shm")
            if fileManager.fileExists(atPath: sourceShm.path) {
                try fileManager.moveItem(at: sourceShm, to: targetShm)
                Logger.info("Migration: Moved .shm file")
            }
            
            Logger.info("Migration: Successfully migrated data to \(targetName)")
            
        } catch {
            Logger.error("Migration: Failed to migrate data. Error: \(error)")
            // 如果迁移失败，可能处于中间状态，这里为了安全起见不进行回滚，让 Core Data 尝试创建新库或报错
        }
    }
}

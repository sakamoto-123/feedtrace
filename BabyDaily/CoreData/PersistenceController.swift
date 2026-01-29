//
//  PersistenceController.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()
    
    // 预览用的内存容器
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // 添加预览数据
        for i in 0..<5 {
            let baby = Baby(context: viewContext)
            baby.id = UUID()
            baby.name = "Baby \(i)"
            baby.birthday = Date()
            baby.createdAt = Date()
            baby.updatedAt = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BabyDaily")
        
        // 内存模式（用于预览和测试）
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 定义新的 Store 名称
            // 修复：为 Debug (开发) 环境和 Release (生产/TestFlight) 环境使用不同的数据库文件名
            // 这可以防止在同一台设备上覆盖安装不同环境的包时，导致本地数据与 CloudKit 环境不匹配（Split Brain）从而产生重复数据
            let storeName: String
            let sharedStoreName: String
            
            #if DEBUG
            storeName = "BabyDaily_CoreData_Dev.sqlite"
            sharedStoreName = "BabyDaily_Shared_Dev.sqlite"
            #else
            storeName = "BabyDaily_CoreData.sqlite"
            sharedStoreName = "BabyDaily_Shared.sqlite"
            #endif
            
            // 1. 尝试执行数据迁移 (从 SwiftData default.store -> BabyDaily_CoreData.sqlite)
            // 注意：如果是在 Debug 模式下使用了新的文件名，这里可能需要调整迁移逻辑，或者仅在 Release 下迁移
            // 目前保持原样，DataMigrationManager 内部可能只处理默认名，但这对新用户无影响
            DataMigrationManager.shared.migrateSwiftDataToCoreData(targetName: storeName)
            
            // 2. 配置 Persistent Store
            // 使用 Application Support 目录 (标准位置)
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                
                // SAFETY CHECK: Ensure the directory exists
                if !FileManager.default.fileExists(atPath: appSupportURL.path) {
                    try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                // --- Private Store Configuration ---
                let privateStoreURL = appSupportURL.appendingPathComponent(storeName)
                let privateDesc = NSPersistentStoreDescription(url: privateStoreURL)
                // privateDesc.configuration = "Private" // 使用默认配置，包含所有实体
                
                // 开启 CloudKit 历史记录追踪 (必须)
                privateDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                privateDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                // 开启自动迁移
                privateDesc.shouldMigrateStoreAutomatically = true
                privateDesc.shouldInferMappingModelAutomatically = true
                
                // 设置 CloudKit Container ID 和 Scope
                let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: CloudKitConfig.containerIdentifier)
                privateOptions.databaseScope = .private
                privateDesc.cloudKitContainerOptions = privateOptions
                
                // --- Shared Store Configuration ---
                let sharedStoreURL = appSupportURL.appendingPathComponent(sharedStoreName)
                let sharedDesc = NSPersistentStoreDescription(url: sharedStoreURL)
                // sharedDesc.configuration = "Shared" // 使用默认配置，包含所有实体
                
                // 开启 CloudKit 历史记录追踪 (必须)
                sharedDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                sharedDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                // 开启自动迁移
                sharedDesc.shouldMigrateStoreAutomatically = true
                sharedDesc.shouldInferMappingModelAutomatically = true
                
                // 设置 CloudKit Container ID 和 Scope
                let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: CloudKitConfig.containerIdentifier)
                sharedOptions.databaseScope = .shared
                sharedDesc.cloudKitContainerOptions = sharedOptions
                
                // 应用配置：同时加载 Private 和 Shared Stores
                container.persistentStoreDescriptions = [privateDesc, sharedDesc]
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 记录错误而不是直接崩溃
                Logger.error("Unresolved error \(error), \(error.userInfo)")
                
                // NEW: Handle CloudKit errors
                CloudKitErrorHandler.shared.handle(error: error)
                
                // 如果是迁移错误或模型不兼容，尝试删除 Store 并重建 (Nuke and Pave)
                // 注意：这会导致本地数据丢失，但在开发阶段或无法打开应用时是必要的恢复手段
                if let url = storeDescription.url {
                    Logger.warning("Attempting to recover by deleting incompatible store at \(url)")
                    do {
                        if FileManager.default.fileExists(atPath: url.path) {
                            try FileManager.default.removeItem(at: url)
                        }
                        // 删除辅助文件
                        try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
                        try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                        
                        // 提示用户重启应用
                        Logger.info("Store deleted. Please restart the app.")
                    } catch {
                        Logger.error("Failed to delete store: \(error)")
                    }
                }
            }
        })
        
        #if DEBUG
        // Initialize CloudKit Schema in Debug mode to ensure zones and record types exist
        // This helps resolve "Zone Not Found" errors during development
        do {
            try container.initializeCloudKitSchema(options: [])
        } catch {
            Logger.error("Failed to initialize CloudKit schema: \(error)")
        }
        #endif
        
        // 自动合并来自父上下文的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        // 合并策略：内存优先 (或数据库优先)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 执行去重检查 (异步执行，避免阻塞启动)
        // 仅在主 Store 加载完成后执行
        if !inMemory {
            // 捕获 container 以避免在 Task 中捕获 mutating self
            let container = container
            Task {
                // 等待一点时间确保 Store 完全加载和 CloudKit 初始同步可能开始
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                DeduplicationManager.shared.deduplicate(in: container.newBackgroundContext())
            }
        }
    }
    
    // MARK: - Sharing Helpers
    
    func share(_ object: NSManagedObject, to participants: [CKShare.Participant]? = nil, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
        // 使用系统 UICloudSharingController 时，通常不需要手动调用此方法，
        // 而是通过 UICloudSharingController(preparationHandler:)
    }
}

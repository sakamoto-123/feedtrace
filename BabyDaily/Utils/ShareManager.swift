//
//  ShareManager.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import Foundation
import CloudKit
import SwiftUI
import CoreData
import Combine

@MainActor
class ShareManager: ObservableObject {
    static let shared = ShareManager()
    
    @Published var isSharing = false
    @Published var currentShare: CKShare?
    @Published var shareOwner: String?
    
    private let container = CKContainer(identifier: CloudKitConfig.containerIdentifier)
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    // MARK: - Share Management
    
    /// 检查宝宝是否已被共享
    func checkShareStatus(for baby: Baby) async {
        guard let share = try? persistenceController.container.fetchShares(matching: [baby.objectID])[baby.objectID] else {
            self.isSharing = false
            self.currentShare = nil
            self.shareOwner = nil
            return
        }
        
        self.currentShare = share
        self.isSharing = true
        
        // 获取 Owner 信息
        if let owner = share.owner.userIdentity.nameComponents {
            self.shareOwner = PersonNameComponentsFormatter().string(from: owner)
        } else {
            self.shareOwner = "owner".localized
        }
    }
    
    /// 创建共享控制器
    /// 手动创建共享（用于避免 UICloudSharingController 白屏问题）
    /// - Returns: 创建好或已存在的 CKShare
    func createShare(for baby: Baby, title: String = "BabyDaily Family") async throws -> CKShare {
        let container = persistenceController.container
        
        // 1. 先检查是否已经存在 Share，如果存在直接返回
        if let shares = try? container.fetchShares(matching: [baby.objectID]),
           let existingShare = shares[baby.objectID] {
            return existingShare
        }

        // 2. 如果不存在，调用 CloudKit API 创建
        return try await withCheckedThrowingContinuation { continuation in
            // 使用 NSPersistentCloudKitContainer 的 share 方法
            container.share([baby], to: nil) { (objectIDs, share, container, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let share = share else {
                    continuation.resume(throwing: NSError(domain: "ShareManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create share"]))
                    return
                }
                
                // 配置 Share 元数据
                share[CKShare.SystemFieldKey.title] = title
                if let photo = baby.photo {
                    share[CKShare.SystemFieldKey.thumbnailImageData] = photo
                }
                
                continuation.resume(returning: share)
            }
        }
    }
    
    func makeCloudSharingController(for baby: Baby, title: String = "BabyDaily Family") -> UIViewController? {
        // 使用 NSPersistentCloudKitContainer 原生共享 API
        let container = persistenceController.container
        
        // 检查是否已经共享
        var share: CKShare?
        do {
            let shares = try container.fetchShares(matching: [baby.objectID])
            share = shares[baby.objectID]
        } catch {
            Logger.error("Failed to fetch existing shares: \(error)")
        }
        
        let sharingController: UICloudSharingController
        
        if let share = share {
            // 已经共享，直接使用现有 Share
            sharingController = UICloudSharingController(share: share, container: self.container)
        } else {
            // 尚未共享，创建新的 Share
            sharingController = UICloudSharingController(preparationHandler: { [weak self] (controller, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) in
                guard let self = self else { return }
                
                // 在后台队列执行，避免阻塞 UI
                container.share([baby], to: nil) { (objectIDs, share, container, error) in
                    if let share = share {
                        // 配置 Share 元数据
                        share[CKShare.SystemFieldKey.title] = title
                        share[CKShare.SystemFieldKey.thumbnailImageData] = baby.photo
                    }
                    
                    DispatchQueue.main.async {
                        completion(share, self.container, error)
                    }
                }
            })
        }
        
        // 配置控制器
        sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
        sharingController.modalPresentationStyle = .formSheet
        
        return sharingController
    }
    
    /// 停止共享
    func stopSharing(for baby: Baby) async throws {
        let container = persistenceController.container
        
        // 获取 Share
        guard let share = try container.fetchShares(matching: [baby.objectID])[baby.objectID] else {
            return
        }
        
        // 删除 Share (这会停止共享)
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [share.recordID])
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // 使用私有数据库 (共享也是存在 Owner 的 Private Database 的 Custom Zone 里)
            self.container.privateCloudDatabase.add(operation)
        }
    }
    
    /// 清理无效的共享记录（用于处理本地有 Share 但云端已删除的情况）
    func cleanupInvalidShare(for baby: Baby) {
        let container = persistenceController.container
        
        // 在后台上下文中执行清理
        container.performBackgroundTask { context in
            // 获取 Baby 对象
            guard let babyInContext = try? context.existingObject(with: baby.objectID) as? Baby else { return }
            
            // 尝试获取关联的 Share
            if let shares = try? container.fetchShares(matching: [babyInContext.objectID]),
               let share = shares[babyInContext.objectID] {
                
                Logger.warning("Cleaning up invalid share for baby: \(baby.name ?? "Unknown")")
                
                // 尝试通过 CloudKit 删除 Share 记录
                // 即使本地 Core Data 无法直接删除 CKShare (因为它不是 NSManagedObject)，
                // 我们尝试发送删除请求，希望这能触发系统的同步机制或清理
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [share.recordID])
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        Logger.info("Successfully removed invalid share from CloudKit")
                    case .failure(let error):
                        Logger.warning("Failed to remove invalid share from CloudKit (expected if zone missing): \(error)")
                    }
                }
                // 使用私有数据库
                self.container.privateCloudDatabase.add(operation)
            }
        }
        
        // 更新 UI 状态
        Task { @MainActor in
            self.isSharing = false
            self.currentShare = nil
            self.shareOwner = nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// 检查 iCloud 权限
    func checkiCloudAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            Logger.error("Checking iCloud status failed: \(error)")
            return false
        }
    }
}

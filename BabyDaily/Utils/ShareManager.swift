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
    
    // 全局 Loading 状态：正在接受共享
    @Published var isAcceptingShare = false
    
    // 正在处理的共享 ID (去重)
    private var processingShareIDs: Set<CKRecord.ID> = []
    
    private let container = CKContainer(identifier: CloudKitConfig.containerIdentifier)
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    // MARK: - Permission Management
    
    /// 请求用户发现权限（解决 Share Owner 名字为 nil 的问题）
    func requestPermissions() {
        container.requestApplicationPermission(.userDiscoverability) { status, error in
            if let error = error {
                Logger.error("Failed to request user discoverability permission: \(error)")
                return
            }
            
            if status == .granted {
                Logger.info("User discoverability permission granted")
            } else {
                Logger.warning("User discoverability permission denied or could not be determined")
            }
        }
    }
    
    // MARK: - Share Management
    
    /// 检查宝宝是否已被共享
    func checkShareStatus(for baby: Baby) async {
        // 1. 先尝试从本地获取（快速显示）
        guard let share = try? persistenceController.container.fetchShares(matching: [baby.objectID])[baby.objectID] else {
            self.isSharing = false
            self.currentShare = nil
            self.shareOwner = nil
            return
        }
        
        self.currentShare = share
        self.isSharing = true
        
        // 更新 UI 显示
        updateOwnerInfo(from: share)
        
        // 2. 主动从 CloudKit 刷新最新的 Share 状态
        // 这解决了“邀请者看到协作者仍为 Pending”的问题，因为本地 Core Data 可能滞后
        // CKShare 没有 databaseScope 属性，通过 Zone Owner 来判断
        let database = (share.recordID.zoneID.ownerName == CKCurrentUserDefaultName) ? self.container.privateCloudDatabase : self.container.sharedCloudDatabase
        let recordID = share.recordID
        
        Task.detached {
            do {
                let record = try await database.record(for: recordID)
                if let remoteShare = record as? CKShare {
                    await MainActor.run {
                        // 确保用户仍停留在同一页面
                        if self.currentShare?.recordID == remoteShare.recordID {
                            self.currentShare = remoteShare
                            self.updateOwnerInfo(from: remoteShare)
                            Logger.info("Successfully refreshed share from CloudKit")
                        }
                    }
                }
            } catch {
                Logger.debug("Failed to refresh share from CloudKit: \(error)")
            }
        }
    }
    
    private func updateOwnerInfo(from share: CKShare) {
        if let owner = share.owner.userIdentity.nameComponents {
            self.shareOwner = PersonNameComponentsFormatter().string(from: owner)
        } else {
            self.shareOwner = "owner".localized
        }
    }
    
    /// 处理 CloudKit 共享链接接受
    func handleCloudKitShare(metadata: CKShare.Metadata) {
        let shareRecordID = metadata.share.recordID
        
        // 去重检查
        guard !processingShareIDs.contains(shareRecordID) else {
            Logger.info("Share \(shareRecordID) is already processing. Skipping.")
            return
        }
        
        // 标记为正在处理
        processingShareIDs.insert(shareRecordID)
        
        // 开启全局 Loading
        self.isAcceptingShare = true
        
        let container = CKContainer(identifier: metadata.containerIdentifier)
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        acceptSharesOperation.perShareResultBlock = { metadata, result in
            switch result {
            case .success(let share):
                Logger.info("Accepted share: \(share)")
            case .failure(let error):
                Logger.error("Failed to accept share: \(error)")
            }
        }
        
        acceptSharesOperation.acceptSharesResultBlock = { [weak self] result in
            guard let self = self else { return }
            
            // 无论成功失败，都在主线程移除处理标记（放在 Loading 消失时比较安全，或者这里直接移除也可以）
            // 这里我们选择在最终 Loading 消失时移除，或者失败时移除
            
            switch result {
            case .success:
                Logger.info("Accept shares operation completed successfully")
                // 启动轮询等待数据同步
                self.waitForShareDataSync(shareRecordID: shareRecordID)
            case .failure(let error):
                Logger.error("Accept shares operation failed: \(error)")
                Task { @MainActor in
                    self.isAcceptingShare = false
                    self.processingShareIDs.remove(shareRecordID)
                }
            }
        }
        
        container.add(acceptSharesOperation)
    }
    
    /// 等待数据同步（轮询策略）
    private func waitForShareDataSync(shareRecordID: CKRecord.ID) {
        Task {
            Logger.info("Starting to wait for shared data sync...")
            
            // 由于很难精确知道哪条数据是新的（没有 ID 映射），
            // 这里采用“最少等待 + 轮询检查”的策略。
            // 给予 Core Data 至少 6 秒的时间来处理 Import。
            // 对于大多数网络环境，这足以让首批数据（如 Baby 对象）到达。
            
            // 1. 强制等待 3 秒
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            
            // 2. 检查是否有数据变化（可选，这里简化为固定延时，保证体验）
            // 如果需要更精确，可以检查 Persistent History，但实现较复杂。
            // 再等待 3 秒，确保图片等资源也尽可能加载
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            
            Logger.info("Finished waiting for share sync.")
            
            await MainActor.run {
                self.isAcceptingShare = false
                self.processingShareIDs.remove(shareRecordID)
                // 可以发送一个通知让 UI 刷新，虽然 Core Data 会自动刷新
                NotificationCenter.default.post(name: NSNotification.Name("CloudKitShareDataSynced"), object: nil)
            }
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

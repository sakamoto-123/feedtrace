//
//  CloudSharingView.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import SwiftUI
import UIKit
import CloudKit

struct CloudSharingView: UIViewControllerRepresentable {
    let baby: Baby
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        // 尝试获取共享控制器
        if let controller = ShareManager.shared.makeCloudSharingController(for: baby) as? UICloudSharingController {
            controller.delegate = context.coordinator
            return controller
        } else {
            // 如果无法创建（例如不支持），返回一个空的控制器并弹出提示
            let fallbackVC = UIViewController()
            fallbackVC.view.backgroundColor = .systemBackground
            
            // 延迟弹出 Alert，因为不能在 makeUIViewController 中直接 present
            DispatchQueue.main.async {
                let alertController = UIAlertController(
                    title: "not_supported".localized,
                    message: "icloud_share_not_supported_description".localized,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "ok".localized, style: .default) { _ in
                    // 点击确定后关闭页面
                    fallbackVC.dismiss(animated: true)
                })
                fallbackVC.present(alertController, animated: true)
            }
            return fallbackVC
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 不需要更新
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudSharingView
        
        init(_ parent: CloudSharingView) {
            self.parent = parent
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            Logger.error("Cloud sharing failed: \(error)")
            
            // 检查是否是由于 Zone 丢失或元数据不一致导致的错误
            // 如果是，尝试清理本地无效的 Share
            if let ckError = error as? CKError {
                if ckError.code == .zoneNotFound || ckError.code == .unknownItem || ckError.code == .serverRecordChanged {
                    Logger.warning("Detected potential stale share. Triggering cleanup.")
                    ShareManager.shared.cleanupInvalidShare(for: parent.baby)
                }
            } else {
                // 对于其他未知错误，也尝试清理，作为一种防御性措施
                // 因为 failedToSaveShareWithError 通常意味着严重错误
                Logger.warning("Cloud sharing failed with generic error. Triggering cleanup.")
                ShareManager.shared.cleanupInvalidShare(for: parent.baby)
            }
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            // 使用自定义标题，如果宝宝有名字则包含名字
            // Baby.name 是非可选类型 String，直接判断是否为空
            let babyName = parent.baby.name
            if !babyName.isEmpty {
                 return String(format: "share_baby_title_format".localized, babyName)
            } else {
                return "share_baby_default_title".localized
            }
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // 优先使用宝宝的照片
            if let photoData = parent.baby.photo {
                return photoData
            }
            // 如果没有照片，可以使用 App 图标或者默认占位图
            // 这里我们返回 nil，系统会自动使用 App 图标作为默认缩略图
            return nil
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            Logger.info("Cloud share saved successfully")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            Logger.info("Cloud sharing stopped")
        }
    }
}

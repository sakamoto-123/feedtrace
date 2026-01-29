//
//  SceneDelegate.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/29.
//

import UIKit
import CloudKit
import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        Logger.info("SceneDelegate: scene(_:willConnectTo:options:) called")
        // 使用 SwiftUI WindowGroup 时，不需要在这里手动创建 UIWindow
        // 只需要确保这个类存在，以便系统可以调用下面的委托方法
        
        // 检查启动时的 connectionOptions 是否包含 CloudKit 共享元数据 (冷启动的另一种形式)
        if let cloudKitShareMetadata = connectionOptions.cloudKitShareMetadata {
            Logger.info("SceneDelegate: Scene connected with CloudKit share metadata (Cold Start)")
            ShareManager.shared.handleCloudKitShare(metadata: cloudKitShareMetadata)
        } else {
            Logger.info("SceneDelegate: Connected without share metadata")
        }
    }

    func scene(_ scene: UIScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Logger.info("SceneDelegate: userDidAcceptCloudKitShareWith called (Warm Start)")
        // 热启动时，系统会调用此方法
        ShareManager.shared.handleCloudKitShare(metadata: cloudKitShareMetadata)
    }
}

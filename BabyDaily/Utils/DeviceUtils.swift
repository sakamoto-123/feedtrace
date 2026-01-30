import UIKit

/// 设备类型检测工具
enum DeviceUtils {

    /// 当前是否为 iPad 平台
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

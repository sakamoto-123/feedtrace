//
//  MembershipManager.swift
//  BabyDaily
//
//  会员状态管理类
//  负责管理会员状态和权限检查
//

import Foundation
import Combine

/// 会员功能枚举
enum MembershipFeature: String, CaseIterable {
    case removeAds = "remove_ads"
    case basicRecords = "basic_records"
    case quickActionRecords = "quick_action_records"
    case chartTrends = "chart_trends"
    case familySharing = "family_sharing"
    case multipleBabies = "multiple_babies"
    case unlimitedWidgets = "unlimited_widgets"
    case unlimitedCustomRecords = "unlimited_custom_records"
    case iCloudSync = "icloud_sync"
    case appleWatch = "apple_watch"
    case futureFeatures = "future_features"
    
    /// 功能名称（本地化）
    var localizedName: String {
        switch self {
        case .removeAds:
            return "remove_ads".localized
        case .basicRecords:
            return "basic_records".localized
        case .quickActionRecords:
            return "quick_action_records".localized
        case .chartTrends:
            return "chart_trends".localized
        case .familySharing:
            return "family_sharing".localized
        case .multipleBabies:
            return "multiple_babies".localized
        case .unlimitedWidgets:
            return "unlimited_widgets".localized
        case .unlimitedCustomRecords:
            return "unlimited_custom_records".localized
        case .iCloudSync:
            return "icloud_sync_backup".localized
        case .appleWatch:
            return "apple_watch_feature".localized
        case .futureFeatures:
            return "future_more_features".localized
        }
    }
    
    /// 是否为免费用户可用
    var isAvailableForFreeUser: Bool {
        switch self {
        case .removeAds, .basicRecords, .quickActionRecords, .chartTrends:
            return true
        default:
            return false
        }
    }
}

/// 会员状态管理器
class MembershipManager: ObservableObject {
    // MARK: - 单例模式
    static let shared = MembershipManager()
    
    // MARK: - Published Properties
    /// 是否为高级会员
    @Published var isPremiumMember: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let iapManager = IAPManager.shared
    
    // MARK: - Initialization
    private init() {
        // 监听IAPManager的会员状态变化
        iapManager.$isPremiumMember
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPremiumMember, on: self)
            .store(in: &cancellables)
        
        // 初始化会员状态
        isPremiumMember = iapManager.isPremiumMember
    }
    
    // MARK: - Feature Check
    /// 检查功能是否可用
    func isFeatureAvailable(_ feature: MembershipFeature) -> Bool {
        if feature.isAvailableForFreeUser {
            return true
        }
        return isPremiumMember
    }
    
    /// 检查多个功能是否都可用
    func areFeaturesAvailable(_ features: [MembershipFeature]) -> Bool {
        return features.allSatisfy { isFeatureAvailable($0) }
    }
}

//
//  SubscriptionReminderManager.swift
//  BabyDaily
//
//  订阅提醒管理器
//  负责检查订阅到期时间并在适当的时候提醒用户
//

import Foundation
import UserNotifications
import Combine
import UIKit

/// 订阅提醒管理器
class SubscriptionReminderManager: ObservableObject {
    // MARK: - 单例模式
    static let shared = SubscriptionReminderManager()
    
    // MARK: - Published Properties
    /// 是否显示到期提醒
    @Published var shouldShowExpirationReminder: Bool = false
    
    /// 提醒消息
    @Published var reminderMessage: String = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let membershipManager = MembershipManager.shared
    private let iapManager = IAPManager.shared
    
    // 提醒阈值（天数）
    private let reminderDaysBeforeExpiration = [3, 1] // 到期前3天和1天提醒
    
    // MARK: - Initialization
    private init() {
        // 监听会员状态变化
        setupObservers()
        
        // 检查订阅状态
        checkSubscriptionStatus()
    }
    
    // MARK: - Setup
    /// 设置观察者
    private func setupObservers() {
        // 合并会员状态和过期时间的变化，使用 debounce 防止重复调用
        Publishers.CombineLatest(
            membershipManager.$membershipStatus,
            membershipManager.$expirationDate
        )
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _ in
            self?.checkSubscriptionStatus()
        }
        .store(in: &cancellables)
        
        // 监听应用进入前台
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkSubscriptionStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Subscription Status Check
    /// 检查订阅状态
    func checkSubscriptionStatus() {
        Logger.info("Checking subscription status for reminders...")
        
        // 重置提醒状态
        shouldShowExpirationReminder = false
        reminderMessage = ""
        
        // 检查是否为订阅会员
        guard membershipManager.membershipType == .subscription else {
            Logger.info("Not a subscription member, no reminder needed")
            return
        }
        
        // 检查会员状态
        guard membershipManager.membershipStatus == .active else {
            if membershipManager.membershipStatus == .expired {
                // 订阅已过期
                shouldShowExpirationReminder = true
                reminderMessage = "subscription_expired_message".localized
                Logger.info("Subscription has expired")
            }
            return
        }
        
        // 检查过期时间
        guard let expirationDate = membershipManager.expirationDate else {
            Logger.warning("Subscription member but no expiration date found")
            return
        }
        
        let now = Date()
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: now, to: expirationDate).day ?? 0
        
        // 检查是否已过期
        if expirationDate <= now {
            // 订阅已过期
            shouldShowExpirationReminder = true
            reminderMessage = "subscription_expired_message".localized
            Logger.info("Subscription has expired")
            
            // 更新会员状态
            Task {
                await iapManager.checkMembershipStatus()
            }
            return
        }
        
        // 检查是否需要提醒
        if daysUntilExpiration <= 3 && daysUntilExpiration > 0 {
            // 即将过期（3天内）
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            if daysUntilExpiration == 1 {
                reminderMessage = String(format: "subscription_expiring_tomorrow".localized, formatter.string(from: expirationDate))
            } else {
                reminderMessage = String(format: "subscription_expiring_soon".localized, daysUntilExpiration, formatter.string(from: expirationDate))
            }
            
            shouldShowExpirationReminder = true
            Logger.info("Subscription expiring in \(daysUntilExpiration) days")
            
            // 安排本地通知（可选）
            scheduleLocalNotification(daysUntilExpiration: daysUntilExpiration, expirationDate: expirationDate)
        } else if daysUntilExpiration == 0 {
            // 今天过期
            reminderMessage = "subscription_expiring_today".localized
            shouldShowExpirationReminder = true
            Logger.info("Subscription expiring today")
            
            // 安排本地通知
            scheduleLocalNotification(daysUntilExpiration: 0, expirationDate: expirationDate)
        }
    }
    
    // MARK: - Local Notification
    /// 安排本地通知
    private func scheduleLocalNotification(daysUntilExpiration: Int, expirationDate: Date) {
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.error("Failed to request notification permission: \(error)")
                return
            }
            
            if !granted {
                Logger.info("Notification permission not granted")
                return
            }
            
            // 创建通知内容
            let content = UNMutableNotificationContent()
            content.title = "subscription_reminder_title".localized
            content.sound = .default
            
            if daysUntilExpiration == 0 {
                content.body = "subscription_expiring_today_notification".localized
            } else if daysUntilExpiration == 1 {
                content.body = "subscription_expiring_tomorrow_notification".localized
            } else {
                content.body = String(format: "subscription_expiring_soon_notification".localized, daysUntilExpiration)
            }
            
            // 设置通知触发时间（在过期前1小时）
            let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: expirationDate) ?? expirationDate
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            // 创建通知请求
            let request = UNNotificationRequest(
                identifier: "subscription_expiration_reminder",
                content: content,
                trigger: trigger
            )
            
            // 添加通知
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    Logger.error("Failed to schedule notification: \(error)")
                } else {
                    Logger.info("Notification scheduled for subscription expiration")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    /// 清除所有订阅相关的通知
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["subscription_expiration_reminder"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["subscription_expiration_reminder"])
        Logger.info("Cleared all subscription reminder notifications")
    }
    
    /// 手动触发检查（用于测试）
    func manualCheck() {
        checkSubscriptionStatus()
    }
}

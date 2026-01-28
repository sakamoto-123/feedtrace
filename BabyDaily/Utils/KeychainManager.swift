//
//  KeychainManager.swift
//  BabyDaily
//
//  Keychain安全存储工具类
//  负责安全地存储和读取会员信息，确保数据在卸载重装后不丢失
//

import Foundation
import Security

/// Keychain管理错误
enum KeychainError: Error {
    case itemNotFound
    case unexpectedData
    case unhandledError(status: OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .unexpectedData:
            return "Unexpected data format"
        case .unhandledError(let status):
            return "Keychain error with status: \(status)"
        }
    }
}

/// Keychain管理器
class KeychainManager {
    // MARK: - 单例模式
    static let shared = KeychainManager()
    
    // MARK: - Keychain配置
    private let service: String
    private let account: String
    
    // MARK: - 初始化
    private init() {
        // 使用Bundle ID作为service标识
        self.service = Bundle.main.bundleIdentifier ?? "cn.iizhi.babydaily"
        self.account = "membership_info"
    }
    
    // MARK: - 存储会员信息
    /// 保存会员信息到Keychain
    /// - Parameter info: 会员信息
    /// - Returns: 是否保存成功
    func saveMembershipInfo(_ info: MembershipInfo) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(info)
            
            // 先尝试删除旧数据
            _ = deleteMembershipInfo()
            
            // 添加新数据
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecSuccess {
                Logger.info("Membership info saved to Keychain successfully")
                return true
            } else {
                Logger.error("Failed to save membership info to Keychain: \(status)")
                return false
            }
        } catch {
            Logger.error("Failed to encode membership info: \(error)")
            return false
        }
    }
    
    // MARK: - 读取会员信息
    /// 从Keychain读取会员信息
    /// - Returns: 会员信息，如果不存在则返回nil
    func loadMembershipInfo() -> MembershipInfo? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                Logger.info("No membership info found in Keychain")
            } else {
                Logger.error("Failed to load membership info from Keychain: \(status)")
            }
            return nil
        }
        
        guard let data = result as? Data else {
            Logger.error("Unexpected data type from Keychain")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let info = try decoder.decode(MembershipInfo.self, from: data)
            Logger.info("Membership info loaded from Keychain successfully")
            return info
        } catch {
            Logger.error("Failed to decode membership info: \(error)")
            return nil
        }
    }
    
    // MARK: - 删除会员信息
    /// 从Keychain删除会员信息
    /// - Returns: 是否删除成功
    func deleteMembershipInfo() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            Logger.info("Membership info deleted from Keychain")
            return true
        } else {
            Logger.error("Failed to delete membership info from Keychain: \(status)")
            return false
        }
    }
    
    // MARK: - 更新会员信息
    /// 更新Keychain中的会员信息
    /// - Parameter info: 新的会员信息
    /// - Returns: 是否更新成功
    func updateMembershipInfo(_ info: MembershipInfo) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(info)
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            if status == errSecSuccess {
                Logger.info("Membership info updated in Keychain successfully")
                return true
            } else if status == errSecItemNotFound {
                // 如果不存在，则添加
                Logger.info("Membership info not found, adding new entry")
                return saveMembershipInfo(info)
            } else {
                Logger.error("Failed to update membership info in Keychain: \(status)")
                return false
            }
        } catch {
            Logger.error("Failed to encode membership info for update: \(error)")
            return false
        }
    }
}

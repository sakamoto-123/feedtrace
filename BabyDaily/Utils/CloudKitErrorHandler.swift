import Foundation
import CloudKit
import CoreData
import SwiftUI
import Combine

class CloudKitErrorHandler: ObservableObject {
    static let shared = CloudKitErrorHandler()
    
    @Published var currentError: IdentifiableError?
    
    struct IdentifiableError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    private init() {
        // Monitor Core Data CloudKit sync events
        NotificationCenter.default.addObserver(self, selector: #selector(cloudKitEventChanged(_:)), name: NSPersistentCloudKitContainer.eventChangedNotification, object: nil)
    }
    
    @objc private func cloudKitEventChanged(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
        
        if let error = event.error {
            handle(error: error)
        }
    }
    
    func handle(error: Error) {
        // Handle CKError
        if let ckError = error as? CKError {
            let (title, message) = getLocalizedMessage(for: ckError)
            
            // Log the error
            Logger.error("CloudKit Sync Error: \(title) - \(message) (Code: \(ckError.code.rawValue))")
            
            #if DEBUG
            DispatchQueue.main.async {
                self.currentError = IdentifiableError(title: title, message: message)
            }
            #endif
        } 
        // Handle NSError (which might wrap CKError)
        else if let nsError = error as NSError? {
             if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? CKError {
                 handle(error: underlyingError)
             } else {
                 // Log other errors but don't show alert to avoid spamming user
                 Logger.error("Non-CloudKit error: \(nsError.localizedDescription)")
             }
        }
    }
    
    private func getLocalizedMessage(for error: CKError) -> (String, String) {
        switch error.code {
        case .quotaExceeded:
            return ("icloud_quota_exceeded_title".localized, "icloud_quota_exceeded_message".localized)
        case .notAuthenticated:
             return ("icloud_not_logged_in_title".localized, "icloud_not_logged_in_message".localized)
        case .networkUnavailable, .networkFailure:
             return ("network_error".localized, "network_unavailable_message".localized)
        case .serverRecordChanged:
            // This is a merge conflict, usually handled silently by Core Data
            return ("Sync Conflict", "Server record changed") 
        case .zoneNotFound, .userDeletedZone:
            return ("Sync Error", "iCloud zone not found. Please try restarting the app.")
        case .partialFailure:
            // Extract the underlying error from partial errors
            if let partialErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: Error] {
                // Iterate to find the first meaningful CKError (skipping generic wrappers if possible)
                // We use compactMap to get valid CKErrors
                let underlyingErrors = partialErrors.values.compactMap { $0 as? CKError }
                
                if let firstError = underlyingErrors.first {
                    // Recursively get the message for the underlying error
                    // This ensures that if the underlying error is .quotaExceeded, we show the correct "Storage Full" message
                    return getLocalizedMessage(for: firstError)
                }
            }
            return ("Sync Error", "Some data failed to sync.")
        default:
            return ("error".localized, error.localizedDescription)
        }
    }
}

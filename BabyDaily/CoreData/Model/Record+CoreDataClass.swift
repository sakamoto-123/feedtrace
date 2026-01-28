//
//  Record+CoreDataClass.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//
//

import Foundation
import CoreData
#if canImport(UIKit)
import UIKit
#endif

@objc(Record)
public class Record: NSManagedObject {
    // 辅助属性：将 Data 转换为 [Data]
    public var photosArray: [Data] {
        get {
            guard let data = photos else { return [] }
            do {
                if let array = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSData.self], from: data) as? [Data] {
                    return array
                }
            } catch {
                print("Failed to unarchive photos: \(error)")
            }

            if let array = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Data]) {
                return array
            }

            if let nsArray = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [NSData]) {
                return nsArray.map { Data(referencing: $0) }
            }

#if canImport(UIKit)
            if UIImage(data: data) != nil {
                return [data]
            }
#endif
            return []
        }
        set {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
                photos = data
            } catch {
                print("Failed to archive photos: \(error)")
                photos = nil
            }
        }
    }
}

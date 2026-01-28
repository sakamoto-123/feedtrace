//
//  Baby+CoreDataProperties.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//
//

import Foundation
import CoreData


extension Baby {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Baby> {
        return NSFetchRequest<Baby>(entityName: "Baby")
    }

    @NSManaged public var birthday: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var gender: String
    @NSManaged public var headCircumference: Double
    @NSManaged public var height: Double
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var photo: Data?
    @NSManaged public var updatedAt: Date
    @NSManaged public var weight: Double
    @NSManaged public var records: NSSet?

}

// MARK: Generated accessors for records
extension Baby {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: Record)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: Record)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}

extension Baby : Identifiable {

}

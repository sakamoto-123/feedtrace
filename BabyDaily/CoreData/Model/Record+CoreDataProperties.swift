//
//  Record+CoreDataProperties.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var acceptance: String?
    @NSManaged public var breastType: String?
    @NSManaged public var category: String
    @NSManaged public var createdAt: Date
    @NSManaged public var dayOrNight: String?
    @NSManaged public var endTimestamp: Date?
    @NSManaged public var excrementStatus: String?
    @NSManaged public var icon: String
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var photos: Data?
    @NSManaged public var remark: String?
    @NSManaged public var startTimestamp: Date
    @NSManaged public var subCategory: String?
    @NSManaged public var unit: String?
    @NSManaged public var updatedAt: Date
    @NSManaged public var value: Double
    @NSManaged public var baby: Baby?

}

extension Record : Identifiable {

}

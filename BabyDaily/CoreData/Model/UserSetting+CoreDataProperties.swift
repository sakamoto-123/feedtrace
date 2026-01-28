//
//  UserSetting+CoreDataProperties.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//
//

import Foundation
import CoreData


extension UserSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSetting> {
        return NSFetchRequest<UserSetting>(entityName: "UserSetting")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var lengthUnit: String
    @NSManaged public var temperatureUnit: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var volumeUnit: String
    @NSManaged public var weightUnit: String

}

extension UserSetting : Identifiable {

}

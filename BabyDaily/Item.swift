//
//  Item.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

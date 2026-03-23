//
//  Item.swift
//  KeyQuest
//
//  Created by Mohammad Rizaldy Ramadhan on 23/03/26.
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

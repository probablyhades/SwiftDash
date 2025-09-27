//
//  Item.swift
//  SwiftDash
//
//  Created by Harry Lewandowski on 27/9/2025.
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

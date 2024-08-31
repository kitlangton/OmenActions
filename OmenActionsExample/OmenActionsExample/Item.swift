//
//  Item.swift
//  OmenActionsExample
//
//  Created by Kit Langton on 12/19/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var name: String = ""
    var timestamp: Date
    
  init(name: String, timestamp: Date) {
        self.name = name
        self.timestamp = timestamp
    }
}

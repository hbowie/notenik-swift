//
//  BooleanValue.swift
//  Notenik
//
//  Created by Herb Bowie on 4/28/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Handle a boolean value as a string.
class BooleanValue: StringValue {
    
    var isTrue: Bool {
        let lower = value.lowercased()
        if lower.hasPrefix("y") {
            return true
        } else if lower.hasPrefix("n") {
            return false
        } else if lower.hasPrefix("t") {
            return true
        } else if lower.hasPrefix("f") {
            return false
        } else if lower == "on" {
            return true
        } else {
            return false
        }
    }
    
}

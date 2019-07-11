//
//  PickList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/11/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A list of values that can be picked from.
class PickList {
    
    var values: [String] = []
    
    /// Register a new value. Add it if not already present in the list.
    func registerValue(_ value: String) {
        var i = 0
        var looking = true
        while looking {
            if i >= values.count {
                values.append(value)
                looking = false
            } else if value == values[i] {
                looking = false
            } else if value < values[i] {
                values.insert(value, at: i)
                looking = false
            }
            i += 1
        }
    }
}

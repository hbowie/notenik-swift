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
    
    var values: [StringValue] = []
    
    /// Register a new value. Add it if not already present in the list.
    func registerValue(_ value: StringValue) -> StringValue {
        
        var index = 0
        var bottom = 0
        var top = values.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if value == values[top] {
                return values[top]
            } else if value == values[bottom] {
                return values[bottom]
            } else if value > values[top] {
                done = true
                index = top + 1
            } else if value < values[bottom] {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if value > values[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if value == values[middle] {
                    return values[middle]
                } else if value > values[middle] {
                    bottom = middle + 1
                } else {
                    top = middle - 1
                }
            }
        }
        
        if index >= values.count {
            values.append(value)
        } else if index < 0 {
            values.insert(value, at: 0)
        } else {
            values.insert(value, at: index)
        }
        return value
    }
}

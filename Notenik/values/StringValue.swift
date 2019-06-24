//
//  StringValue.swift
//  notenik
//
//  Created by Herb Bowie on 11/25/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A base value class for plain old strings
class StringValue: CustomStringConvertible, Equatable, Comparable {
    
    var value = ""
    
    /// Initialize with no initial value
    init() {
        
    }
    
    /// Initialize with a String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Set a new value for the objecct
    func set(_ value: String) {
        self.value = value
    }
    
    /// Return the length of the string
    var count: Int {
        return value.count
    }
    
    /// Return the description, used as the String value for the object
    var description: String {
        return value
    }
    
    /// Is this value empty?
    var isEmpty: Bool {
        return (value.count == 0)
    }
    
    /// Does this value have any data stored in it?
    var hasData: Bool {
        return (value.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    var sortKey: String {
        return value
    }
    
    /// See if two of these objects have equal keys
    static func ==(lhs: StringValue, rhs: StringValue) -> Bool {
        return lhs.sortKey == rhs.sortKey
    }
    
    /// See which of these objects should come before the other in a sorted list
    static func < (lhs: StringValue, rhs: StringValue) -> Bool {
      return lhs.sortKey < rhs.sortKey
    }
    
    /// Perform the requested operation with a possible value.
    func operate(opcode: String, operand1: String) {
        switch opcode {
        case "=":
            set(operand1)
        case "+=", "+":
            value += operand1
        default:
            Logger.shared.log(subsystem: "values", category: "StringValue", level: .error,
                              message: "Invalid operator of \(opcode) for a String value")
        }
    }
    
}

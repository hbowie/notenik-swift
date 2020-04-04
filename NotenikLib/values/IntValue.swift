//
//  IntValue.swift
//  Notenik
//
//  Created by Herb Bowie on 6/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A title field value
class IntValue: StringValue {
    
    /// The lowest common denominator of the title (lower case, no whitespace, no punctuation)
    var int = 0
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Is this value empty?
    override var isEmpty: Bool {
        return (value.count == 0)
    }
    
    /// Does this value have any data stored in it?
    override var hasData: Bool {
        return (value.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return String(format: "%08d", int)
    }
    
    /// Set a new title value, converting to a lowest common denominator form while we're at it
    override func set(_ value: String) {
        super.set(value)
        let possibleInt = Int(value)
        if possibleInt != nil {
            int = possibleInt!
        }
    }
    
    /// Perform the requested operation with a possible value.
    override func operate(opcode: String, operand1: String) {
        var possibleInt = Int(operand1)
        if possibleInt == nil {
            if operand1.count > 0 {
                Logger.shared.log(subsystem: "values", category: "IntValue", level: .error,
                              message: "Value of \(operand1) cannot be used as an integer.")
                return
            } else {
                possibleInt = 0
            }
        }
        switch opcode {
        case "=":
            set(operand1)
        case "+=", "+":
            int += possibleInt!
            value = String(int)
        case "++":
            int += 1
            value = String(int)
        case "-+", "-":
            int -= possibleInt!
            value = String(int)
        case "--":
            int -= 1
            value = String(int)
        default:
            Logger.shared.log(subsystem: "values", category: "IntValue", level: .error,
                              message: "Invalid operator of \(opcode) for an integer value")
        }
    }
    
}

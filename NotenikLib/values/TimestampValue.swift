//
//  TimestampValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class TimestampValue: StringValue {
    
    override init() {
        super.init()
        now()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        if value.count == 0 {
            now()
        } else {
            set(value)
        }
    }
    
    /// Set this value to the current date and time.
    func now() {
        let rightNow = Date()
        value = DateUtils.shared.timestampFormatter.string(from: rightNow)
    }
    
    override func set(_ value: String) {
        self.value = ""
        for char in value {
            if char == "+" { break }
            if char.isNumber {
                self.value.append(char) 
            }
        }
    }
    
}

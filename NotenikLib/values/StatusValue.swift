//
//  StatusValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/7/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A representation of an item's status using both a string label and an integer value
class StatusValue: StringValue {
    
    var statusInt = 0
    
    /// Convenience initializer using an integer and a Status Value Config
    convenience init (i: Int, config: StatusValueConfig) {
        self.init()
        set(i: i, config: config)
    }
    
    /// Convenience initializer using a string and a Status Value Config
    convenience init (str: String, config: StatusValueConfig) {
        self.init()
        set(str: str, config: config)
    }
    
    /// Toggle between most complete status and least complete.
    func toggle(config: StatusValueConfig) {
        var toggleIndex = 0
        if statusInt >= config.highIndex {
            toggleIndex = config.lowIndex
        } else {
            toggleIndex = config.highIndex
        }
        set(i: toggleIndex, config: config)
    }
    
    /// Increment this status to the next valid value. 
    func increment(config: StatusValueConfig) {
        var incIndex = 0
        if statusInt < config.highIndex {
            incIndex = statusInt + 1
            while incIndex < 9 && !config.validStatus(incIndex) {
                incIndex += 1
            }
            set(i: incIndex, config: config)
        }
    }
    
    /// Close the Note
    func close(config: StatusValueConfig) {
        let closeIndex = config.statusOptions.count - 1
        set(i: closeIndex, config: config)
    }
    
    /// Set the status using an integer and the passed Status Value Config
    func set (i: Int, config: StatusValueConfig) {
        if config.validStatus(i) {
            self.value = config.get(i)
        }
    }
    
    /// Set the status integer based on the current label value
    func set(_ config: StatusValueConfig) {
        set (str: value, config: config)
    }
    
    /// Set the status using a string and the passed Status Value Config
    func set(str: String, config: StatusValueConfig) {
        super.set(str)
        var i = config.get(str)
        if i >= 0 {
            statusInt = i
        } else {
            let trimmed = StringUtils.trim(str)
            if trimmed.count >= 1 {
                let c = StringUtils.charAt(index: 0, str: trimmed)
                if StringUtils.isDigit(c) {
                    i = Int(String(c))!
                    if config.validStatus(i) {
                        statusInt = i
                        self.value = config.get(i)
                    }
                }
            }
        }
    }
    
    
    /// Return an "X" for an item that is past the done threshold.
    ///
    /// - Parameter config: The Status Value Configuration to use.
    /// - Returns: An 'X' if done, a space otherwise. 
    func doneX(config: StatusValueConfig) -> String {
        if isDone(config: config) {
            return "X"
        } else {
            return " "
        }
    }
    
    /// Compare this status value to the config's done threshold to
    /// see if this item qualifies as 'Done'.
    ///
    /// - Parameter config: The Status Value Configuration to use.
    /// - Returns: True if done; false otherwise.
    func isDone(config: StatusValueConfig) -> Bool {
        return statusInt >= config.doneThreshold
    }
    
    /// Get the integer representation of this status value
    func getInt() -> Int {
        return statusInt
    }
    
}

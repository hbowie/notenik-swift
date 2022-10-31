//
//  RankDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 10/23/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class RankDataSource: NSObject, NSComboBoxDataSource {
    
    var config: RankValueConfig!
    
    init(config: RankValueConfig) {
        super.init()
        self.config = config
    }
    
    /// Returns the first item from the list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var number = 0
        var label = ""
        var digits = 0
        for c in string {
            if c.isWholeNumber {
                if let i = Int(String(c)) {
                    number = (number * 10) + i
                    digits += 1
                }
            } else if label.count > 0 {
                label.append(c)
            } else if !c.isWhitespace {
                label.append(c)
            }
        }
        let labelLower = label.lowercased()
        for possible in config.possibleValues {
            if possible.number == number && number > 0 {
                return possible.get(config: config)
            } else if !label.isEmpty && possible.label.starts(with: label) {
                return possible.label
            } else if !label.isEmpty && possible.labelLowered.starts(with: labelLower) {
                return possible.labelLowered
            } else if possible.number == number && digits > 0 {
                return possible.get(config: config)
            }
        }
        return nil
    }
    
    /// Returns the index of the item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        let strLower = string.lowercased()
        var index = 0
        for possible in config.possibleValues {
            if strLower == possible.labelLowered {
                return index
            } else if possible.get(config: config).lowercased().hasSuffix(strLower) {
                return index
            } else {
                index += 1
            }
        }
        return NSNotFound
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 else { return nil }
        guard index < config.possibleValues.count else { return nil }
        return config.possibleValues[index].get(config: config)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return config.possibleValues.count
    }
    
}

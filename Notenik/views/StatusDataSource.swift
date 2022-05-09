//
//  StatusDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/22.
//  Copyright © 2022 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class StatusDataSource: NSObject, NSComboBoxDataSource {
    
    var config: StatusValueConfig!
    
    var statusValues: [String] = []
    
    init(config: StatusValueConfig) {
        super.init()
        self.config = config
        loadArray()
    }
    
    func loadArray() {
        statusValues = []
        for option in config.statusOptions {
            if !option.isEmpty {
                statusValues.append(option.lowercased())
            }
        }
        for value in config.freeformValues {
            statusValues.append(value.lowercased())
        }
    }
    
    // Returns the number of items that the data source manages for the combo box
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return statusValues.count
    }
        
    // Returns the object that corresponds to the item at the specified index in the combo box
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
      return statusValues[index]
    }
    
    // Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        
        var lookingFor = string.lowercased()
        
        guard let firstChar = string.first else { return nil }
        if let i = Int(String(firstChar)) {
            let value = config.get(i)
            if !value.isEmpty {
                lookingFor = value.lowercased()
            }
        }
        
        for value in statusValues {
            if value.starts(with: lookingFor) {
                return value
            }
        }
        
        return nil
    }
    
    // Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var i = 0
        while i < statusValues.count {
            let value = statusValues[i]
            if value == string {
                return i
            }
            i += 1
        }
        return NSNotFound
    }

}

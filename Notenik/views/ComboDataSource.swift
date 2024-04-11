//
//  ComboDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 5/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ComboDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var comboList = ComboList()
    
    var fieldDef: FieldDefinition?
    
    var comboField: NSComboBox?
    
    override init() {
        super.init()
    }
    
    public convenience init(def: FieldDefinition, field: NSComboBox) {
        self.init()
        self.fieldDef = def
        self.comboField = field
        if fieldDef!.comboList != nil {
            switch fieldDef!.fieldType.typeString {
            case NotenikConstants.comboType:
                comboList = fieldDef!.comboList!
            case NotenikConstants.folderCommon:
                comboList = fieldDef!.comboList!
            default:
                break
            }
        }
        if fieldDef!.fieldType.typeString == NotenikConstants.comboType && fieldDef!.comboList != nil {
            comboList = fieldDef!.comboList!
        }
    }
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return comboList.count
    }
    
    /// Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return comboList.valueAt(index)
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        
        let lookingFor = string.lowercased()
        var i = 0
        while i < comboList.count {
            if let lower = comboList.lowerAt(i) {
                if lower.starts(with: lookingFor) {
                    if let value = comboList.valueAt(i) {
                        return value
                    }
                }
            }
            i += 1
        }
        return nil
    }
    
    /// Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        
        let lookingFor = string.lowercased()
        var i = 0
        while i < comboList.count {
            if let lower = comboList.lowerAt(i) {
                if lower.starts(with: lookingFor) {
                    return i
                }
            }
            i += 1
        }
        return NSNotFound
    }
    
}


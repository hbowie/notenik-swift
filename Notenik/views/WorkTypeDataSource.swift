//
//  WorkTypeDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class WorkTypeDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    let types = WorkTypeList.shared
    
    /// Initialization.
    override init() {
        super.init()
    }
    
    public var count: Int {
        return types.count
    }
    
    /// Return number of Items to be displayed in the Combo Box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return types.allTypes.count
    }
    
    /// Return the item at the specified index. 
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return types.itemAt(index: index)
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        return types.startsWith(prefix: string)
    }
    
    /// Returns the index of the combo box item
    /// matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return types.matches(value: string)
    }

}

//
//  KlassDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 10/22/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class KlassDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var klassList = KlassPickList()
    
    override init() {
        super.init()
    }
    
    init(pickList: KlassPickList) {
        super.init()
        klassList = pickList
    }
    
    public var count: Int {
        return klassList.count
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return klassList.count
    }
    
    public var defaultValue: String {
        return klassList.defaultValue
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return itemAt(index: index)
    }
    
    public func itemAt(index: Int) -> String? {
        return klassList.stringAt(index: index)
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        let value = klassList.startsWith(prefix: string)
        if value == nil {
            return nil
        } else {
            return value!.value
        }
    }
    
    /// Returns the index of the combo box item
    /// matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return klassList.matches(value: string)
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        // print("Work Title Selection Did Change!")
    }
}

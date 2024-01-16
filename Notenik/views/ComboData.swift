//
//  ComboData.swift
//  Notenik
//
//  Created by Herb Bowie on 12/2/22.
//  Copyright © 2022 - 2024 PowerSurge Publishing. All rights reserved.
//

import Cocoa

/// Provide a useful data source for a combo box. 
class ComboData: NSObject, NSComboBoxDataSource {
    
    var items: [ComboItem] = []
    var sorted = false
    
    override init() {
        super.init()
    }
    
    public func clearItems() {
        items = []
    }
    
    /// Add another item to the list, without sorting or checking for duplicates.
    public func addItem(_ str: String) {
        let anotherItem = ComboItem(str)
        items.append(anotherItem)
        sorted = false
    }
    
    /// Add a new item to the list, avoiding duplicates, and keeping the list in order.
    public func registerItem(_ str: String) {
        
        guard !str.isEmpty else { return }
        
        let anotherItem = ComboItem(str)
        
        if !sorted {
            sortItems()
        }
        
        var i = 0
        while i < items.count {
            if anotherItem == items[i] {
                return
            } else if anotherItem < items[i] {
                items.insert(anotherItem, at: i)
                return
            } else {
                i += 1
            }
        }
        items.append(anotherItem)
    }
    
    /// Sort the list. 
    func sortItems() {
        items.sort()
        sorted = true
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Provide Data Source functionality for the Combo Box.
    //
    // -----------------------------------------------------------
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return items.count
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed. 
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        let lookingFor = string.lowercased()
        for item in items {
            if item.strLower.starts(with: lookingFor) {
                return item.str
            }
        }
        return nil
    }
    
    /// Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        let lookingFor = string.lowercased()
        var i = 0
        while i < items.count {
            if lookingFor == items[i].strLower {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
    /// Returns the object that corresponds to the item at the specified index in the combo box. 
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }

}

//
//  PickListDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 5/11/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class PickListDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var list = PickList()
    
    override init() {
        super.init()
    }
    
    convenience init(list: PickList) {
        self.init()
        self.list = list
    }
    
    var count: Int {
        return list.count
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return list.count
    }
    
    func item(at: Int) -> String? {
        if at < 0 || at >= list.count {
            return nil
        } else {
            return list.values[at].value
        }
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 && index < list.count else { return "" }
        return list.values[index].value
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var i = 0
        while i < list.count {
            if list.values[i].value.hasPrefix(string) {
                return list.values[i].value
            } else if list.values[i].value > string {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Returns the index of the combo box item
    /// matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var i = 0
        while i < list.count {
            if list.values[i].value == string {
                return i
            } else if list.values[i].value > string {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
}


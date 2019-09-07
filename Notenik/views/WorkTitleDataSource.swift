//
//  WorkTitleDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class WorkTitleDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var workTitlePickList = WorkTitlePickList()
    
    override init() {
        super.init()
    }
    
    convenience init(workTitlePickList: WorkTitlePickList) {
        self.init()
        self.workTitlePickList = workTitlePickList
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return workTitlePickList.values.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return workTitlePickList.values[index]
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var i = 0
        while i < workTitlePickList.values.count {
            if workTitlePickList.values[i].hasPrefix(string) {
                return workTitlePickList.values[i]
            } else if workTitlePickList.values[i] > string {
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
        while i < workTitlePickList.values.count {
            if workTitlePickList.values[i] == string {
                return i
            } else if workTitlePickList.values[i] > string {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
    
}

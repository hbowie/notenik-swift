//
//  AuthorDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class AuthorDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var authorPickList = AuthorPickList()
    
    override init() {
        super.init()
    }
    
    convenience init(authorPickList: AuthorPickList) {
        self.init()
        self.authorPickList = authorPickList
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return authorPickList.values.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return authorPickList.values[index].value
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var i = 0
        while i < authorPickList.values.count {
            if authorPickList.values[i].value.hasPrefix(string) {
                return authorPickList.values[i].value
            } else if authorPickList.values[i].value > string {
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
        while i < authorPickList.values.count {
            if authorPickList.values[i].value == string {
                return i
            } else if authorPickList.values[i].value > string {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
}

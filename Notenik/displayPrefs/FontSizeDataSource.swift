//
//  FontSizeDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 3/4/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class FontSizeDataSource: NSObject,  NSComboBoxDataSource {
    
    var fontsFor: FontsFor = .body
    
    var sizes: [String] = []
    
    var bodySizes: [String] = ["08", "10", "12", "13", "14", "15", "16", "18", "20", "24", "28", "36"]
    
    var headingSizes: [String] = ["1.0", "1.2", "1.4", "1.6", "1.8", "2.0", "2.2", "2.4", "2.6", "2.8", "3.0"]
    
    override init() {
        super.init()
        sizes = bodySizes
    }
    
    /// Supply sizes for the body type, or for headings?
    func setFontsFor(_ fontsFor: FontsFor) {
        self.fontsFor = fontsFor
        switch fontsFor {
        case .body:
            sizes = bodySizes
        case .headings:
            sizes = headingSizes
        case .list:
            sizes = bodySizes
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: NSComboBoxDataSource methods
    //
    // -----------------------------------------------------------
    
    /// Returns the number of items that the data source manages for
    /// the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return numberOfItems
    }
    
    /// Returns the first item from the list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var index = 0
        while index < numberOfItems {
            let item = itemAt(index)
            if item!.hasPrefix(string) {
                return item
            }
            if item! > string {
                return nil
            }
            index += 1
        }
        return nil
    }
    
    /// Returns the index of the item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        let index = indexFor(string)
        if index < 0 {
            return NSNotFound
        } else {
            return index
        }
    }
    
    /// Returns the object that corresponds to the item at the specified index.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return itemAt(index)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utility methods.
    //
    // -----------------------------------------------------------
    
    func indexFor(_ str: String) -> Int {
        var index = 0
        while index < numberOfItems {
            let item = itemAt(index)
            if item == str {
                return index
            }
            index += 1
        }
        return -1
    }
    
    func itemAt(_ index: Int) -> String? {
        if index >= 0 && index < numberOfItems {
            return sizes[index]
        }
        return nil
    }
    
    var numberOfItems: Int {
        return sizes.count
    }
    
}

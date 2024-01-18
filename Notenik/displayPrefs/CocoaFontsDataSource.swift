//
//  DisplayFontsDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 11/10/20.
//  Copyright © 2020 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CocoaFontsDataSource: NSObject,  NSComboBoxDataSource {
    
    var useShort = true
    
    let systemFont = "- System Font -"
    
    var shortList: [String] = [
        "American Typewriter",
        "Andale Mono",
        "Arial",
        "Avenir",
        "Avenir Next",
        "Baskerville",
        "Big Caslon",
        "Bookman",
        "Courier",
        "Courier New",
        "Futura",
        "Garamond",
        "Georgia",
        "Gill Sans",
        "Helvetica",
        "Helvetica Neue",
        "Hoefler Text",
        "Lucida Grande",
        "Menlo",
        "Palatino",
        "Tahoma",
        "Times",
        "Times New Roman",
        "Trebuchet",
        "Verdana"
    ]
    
    var longList: [String] = []
    
    /// Use a long list of all system fonts, or a short list of common fonts?
    func useLongList(_ yes: Bool) {
        if yes {
            longList = NSFontManager.shared.availableFontFamilies
            useShort = false
        } else {
            useShort = true
        }
    }
    
    func addSystemFont(_ yes: Bool) {
        extraFontForSystem = yes
        if yes {
            extraAdjustment = 1
        } else {
            extraAdjustment = 0
        }
    }
    private var extraFontForSystem = false
    private var extraAdjustment = 0
    
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
        let strLowered = string.lowercased()
        let lowered = (string == strLowered)
        while index < numberOfItems {
            let item = itemAt(index)
            if item!.hasPrefix(string) {
                return item
            }
            if lowered && item!.lowercased().hasPrefix(string) {
                return item
            }
            if lowered {
                if item!.lowercased() > string {
                    return nil
                }
            } else if item! > string {
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
    
    func indexFor(_ family: String) -> Int {
        var index = 0
        let strLowered = family.lowercased()
        if extraFontForSystem && strLowered.contains("system font") {
            return 0
        }
        if extraFontForSystem {
            index = 1
        }
        while index < numberOfItems {
            let item = itemAt(index)
            if item == family || item!.lowercased() == strLowered {
                return index
            }
            index += 1
        }
        return -1
    }
    
    func itemAt(_ index: Int) -> String? {
        if index == 0 && extraFontForSystem {
            return systemFont
        } else if index >= 0 && index < numberOfItems {
            if useShort {
                return shortList[index - extraAdjustment]
            } else {
                return longList[index - extraAdjustment]
            }
        }
        return nil
    }
    
    var numberOfItems: Int {
        if useShort {
            return shortList.count + extraAdjustment
        } else {
            return longList.count + extraAdjustment
        }
    }
    
}

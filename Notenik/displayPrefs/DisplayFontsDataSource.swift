//
//  DisplayFontsDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 11/10/20.
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class DisplayFontsDataSource: NSObject,  NSComboBoxDataSource {
    
    var useShort = true
    
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
    
    func useLongList(_ yes: Bool) {
        if yes {
            longList = NSFontManager.shared.availableFontFamilies
            useShort = false
        } else {
            useShort = true
        }
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return numberOfItems
    }
    
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var index = 0
        while index < numberOfItems {
            let item = itemAt(index)
            if item!.hasPrefix(string) {
                return item
            }
            if item! < string {
                return nil
            }
            index += 1
        }
        return nil
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        let index = indexFor(string)
        if index < 0 {
            return NSNotFound
        } else {
            return index
        }
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return itemAt(index)
    }
    
    func indexFor(_ family: String) -> Int {
        var index = 0
        while index < numberOfItems {
            let item = itemAt(index)
            if item == family {
                return index
            }
            index += 1
        }
        return -1
    }
    
    func itemAt(_ index: Int) -> String? {
        if index >= 0 && index < numberOfItems {
            if useShort {
                return shortList[index]
            } else {
                return longList[index]
            }
        }
        return nil
    }
    
    var numberOfItems: Int {
        if useShort {
            return shortList.count
        } else {
            return longList.count
        }
    }
    
}

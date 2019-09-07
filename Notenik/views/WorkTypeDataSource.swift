//
//  WorkTypeDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class WorkTypeDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var types = ["unknown", "Album", "Article", "Blog Post", "Book", "CD", "Comment", "Conference", "Essay", "Film", "Interview", "Lecture", "Letter", "Paper", "Play", "Poem", "Preface", "Presentation", "Remarks", "Sermon", "Song", "Speech", "Story", "Television Show", "Video"]
    
    override init() {
        super.init()
        types.sort()
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return types.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return types[index]
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        var i = 0
        while i < types.count {
            if types[i].hasPrefix(string) {
                return types[i]
            } else if types[i] > string {
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
        while i < types.count {
            if types[i] == string {
                return i
            } else if types[i] > string {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
}

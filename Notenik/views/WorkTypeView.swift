//
//  WorkTypeView.swift
//  Notenik
//
//  Created by Herb Bowie on 8/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import Cocoa

class WorkTypeView: CocoaEditView {
    
    var comboBox: NSComboBox!
    
    let types = ["unknown", "Album", "Article", "Blog Post", "Book", "CD", "Comment", "Conference", "Essay", "Film", "Interview", "Lecture", "Letter", "Paper", "Play", "Poem", "Preface", "Presentation", "Remarks", "Sermon", "Song", "Speech", "Story", "Television Show", "Video"]
    
    var view: NSView {
        return comboBox
    }
    
    var text: String {
        get {
            if comboBox.indexOfSelectedItem >= 0 {
                return types[comboBox.indexOfSelectedItem]
            } else {
                return comboBox.stringValue
            }
        }
        set {
            var found = false
            var i = 0
            let newLower = newValue.lowercased()
            while !found && i < types.count {
                if newLower == types[i].lowercased() {
                    comboBox.selectItem(at: i)
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                comboBox.stringValue = newValue
            }
        }
    }
    
    init() {
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {
        comboBox = NSComboBox()
        for type in types {
            comboBox.addItem(withObjectValue: AppPrefs.shared.makeUserAttributedString(text: type))
        }
        comboBox.selectItem(at: 0)
        AppPrefs.shared.setRegularFont(object: comboBox)
    }

}

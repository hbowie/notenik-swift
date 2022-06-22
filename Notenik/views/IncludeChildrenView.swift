//
//  IncludeChildrenView.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class IncludeChildrenView: MacEditView {
    
    let values = IncludeChildrenList.shared.values
    
    var includeChildrenField: NSPopUpButton!
    
    var view: NSView {
        return includeChildrenField
    }
    
    var text: String {
        get {
            if includeChildrenField.indexOfSelectedItem >= 0 {
                let selectedItem = values[includeChildrenField.indexOfSelectedItem]
                return selectedItem
            } else {
                return includeChildrenField.stringValue
            }
        }
        set {
            let newLower = newValue.lowercased()
            var i = 0
            for value in values {
                if newLower.isEmpty {
                    if value == IncludeChildrenList.no {
                        includeChildrenField.selectItem(at: i)
                    }
                } else if value.starts(with: newLower) {
                    includeChildrenField.selectItem(at: i)
                    return
                }
                i += 1
            }
        }
    }
    
    init() {
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {

        includeChildrenField = NSPopUpButton()
        for value in values {
            includeChildrenField.addItem(withTitle: value)
        }
        includeChildrenField.selectItem(withTitle: IncludeChildrenList.no)
        AppPrefsCocoa.shared.setTextEditingFont(object: includeChildrenField)
    }

}


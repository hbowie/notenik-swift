//
//  KlassView.swift
//  Notenik
//
//  Created by Herb Bowie on 10/22/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class KlassView: MacEditView {
    
    var klassField: NSComboBox!
    let dataSource = KlassDataSource()
    
    var view: NSView {
        return klassField
    }
    
    var text: String {
        get {
            if klassField.indexOfSelectedItem >= 0 {
                let selectedItem = dataSource.itemAt(index: klassField.indexOfSelectedItem)
                return selectedItem!
            } else {
                return klassField.stringValue
            }
        }
        set {
            var found = false
            var i = 0
            let newLower = newValue
            while !found && i < dataSource.count {
                if newLower == dataSource.itemAt(index: i) {
                    klassField.selectItem(at: i)
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                klassField.stringValue = newValue
            }
        }
    }
    
    init() {
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {

        klassField = NSComboBox(string: "")
        klassField.usesDataSource = true
        klassField.dataSource = dataSource
        klassField.delegate = dataSource
        klassField.completes = true
        AppPrefsCocoa.shared.setRegularFont(object: klassField)
    }

}

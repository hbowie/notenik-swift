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

import Cocoa

import NotenikLib

class WorkTypeView: MacEditView {
    
    var workTypeField: NSComboBox!
    let dataSource = WorkTypeDataSource()
    
    var view: NSView {
        return workTypeField
    }
    
    var text: String {
        get {
            if workTypeField.indexOfSelectedItem >= 0 {
                return dataSource.types[workTypeField.indexOfSelectedItem]
            } else {
                return workTypeField.stringValue
            }
        }
        set {
            var found = false
            var i = 0
            let newLower = newValue.lowercased()
            while !found && i < dataSource.types.count {
                if newLower == dataSource.types[i].lowercased() {
                    workTypeField.selectItem(at: i)
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                workTypeField.stringValue = newValue
            }
        }
    }
    
    init() {
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {

        workTypeField = NSComboBox(string: "")
        workTypeField.usesDataSource = true
        workTypeField.dataSource = dataSource
        workTypeField.delegate = dataSource
        workTypeField.completes = true
        AppPrefs.shared.setRegularFont(object: workTypeField)
    }

}

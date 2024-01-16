//
//  LookupView.swift
//  Notenik
//
//  Created by Herb Bowie on 8/21/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class LookupView: MacEditView {
    
    var fieldDef: FieldDefinition
    var lookupField: NSComboBox!
    var lookupDataSource: LookupDataSource!
    
    var view: NSView {
        return lookupField
    }
    
    var text: String {
        get {
            return lookupField.stringValue
        }
        set {
            lookupField.stringValue = newValue
        }
    }
    
    init(def: FieldDefinition) {
        self.fieldDef = def
        buildView()
    }
    
    func buildView() {
        lookupField = NSComboBox(string: "")
        lookupField.usesDataSource = true
        lookupDataSource = LookupDataSource(def: fieldDef, field: lookupField)
        lookupField.dataSource = lookupDataSource
        // lookupField.delegate = lookupDataSource
        lookupField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: lookupField)
    }
    
    func refreshData() {
        lookupDataSource.refreshData()
    }
    
}

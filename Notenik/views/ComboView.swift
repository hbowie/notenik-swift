//
//  ComboView.swift
//  Notenik
//
//  Created by Herb Bowie on 5/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ComboView: MacEditView {
    
    var fieldDef: FieldDefinition
    var comboField: NSComboBox!
    var comboDataSource: ComboDataSource!
    
    var view: NSView {
        return comboField
    }
    
    var text: String {
        get {
            return comboField.stringValue
        }
        set {
            comboField.stringValue = newValue
        }
    }
    
    init(def: FieldDefinition) {
        self.fieldDef = def
        buildView()
    }
    
    func buildView() {
        comboField = NSComboBox(string: "")
        comboField.usesDataSource = true
        comboDataSource = ComboDataSource(def: fieldDef, field: comboField)
        comboField.dataSource = comboDataSource
        comboField.delegate = comboDataSource
        comboField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: comboField)
    }
    
}

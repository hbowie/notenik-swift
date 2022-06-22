//
//  ShortIdView.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ShortIdView: MacEditView {
    
    var textField: NSTextField!
    
    var view: NSView {
        return textField
    }
    
    var text: String {
        get {
            return textField.stringValue
        }
        set {
            textField.stringValue = newValue
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        textField = NSTextField(labelWithString: "")
        AppPrefsCocoa.shared.setTextEditingFont(object: textField)
        textField.isSelectable = true
    }
    
}

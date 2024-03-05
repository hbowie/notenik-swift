//
//  DurationView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/3/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class DurationView: MacEditView {
    
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
        textField = NSTextField(string: "")
        textField.placeholderString = "hh:mm"
        AppPrefsCocoa.shared.setTextEditingFont(object: textField)
    }
    
}

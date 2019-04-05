//
//  StringView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class StringView: CocoaEditView {
    
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
        // textField.translatesAutoresizingMaskIntoConstraints = true
        // textField.autoresizingMask = [.width]
        // textField.isEditable = true
        // textField.isSelectable = true
        // textField.alignment = .left
        // textField.preferredMaxLayoutWidth = 300
    }
    
}

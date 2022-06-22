//
//  BooleanView.swift
//  Notenik
//
//  Created by Herb Bowie on 8/2/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class BooleanView: MacEditView {
    
    var booleanField: NSButton!
    
    var view: NSView {
        return booleanField
    }
    
    var text: String {
        get {
            if booleanField.state == .on {
                return "true"
            } else {
                return "false"
            }
        }
        set {
            let bv = BooleanValue(newValue)
            if bv.isTrue {
                booleanField.state = .on
            } else {
                booleanField.state = .off
            }
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        booleanField = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        AppPrefsCocoa.shared.setTextEditingFont(object: booleanField)
    }
    
}

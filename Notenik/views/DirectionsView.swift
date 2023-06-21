//
//  DirectionsView.swift
//  Notenik
//
//  Created by Herb Bowie on 6/20/23.

//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class DirectionsView: MacEditView {
    
    var booleanField: NSButton!
    
    var view: NSView {
        return booleanField
    }
    
    var _text = ""
    var text: String {
        get {
            return _text
        }
        set {
            _text = newValue
            if _text.isEmpty {
                booleanField.state = .off
            } else {
                booleanField.state = .on
            }
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        booleanField = NSButton(checkboxWithTitle: "Generate Navigation?",
                                target: self,
                                action: #selector(takeAction(sender: )))
        booleanField.state = .off
        AppPrefsCocoa.shared.setTextEditingFont(object: booleanField)
    }
    
    @IBAction func takeAction(sender: Any) {
        if booleanField.state == .off {
            _text = ""
        } else {
            text = NotenikConstants.directionsRequested
        }
    }
    
}

//
//  AuxTextView.swift
//  Notenik
//
//  Created by Herb Bowie on 6/14/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class AuxTextView: MacEditView {
    
    var properLabel = ""
    var typeString  = ""
    
    let appPrefsCocoa = AppPrefsCocoa.shared
    
    var stack:      NSStackView!
    var textField:  NSTextField!
    var editButton: NSButton!
    
    let auxStoryboard: NSStoryboard = NSStoryboard(name: "AuxTextEdit", bundle: nil)
    
    var view: NSView {
        return stack
    }
    
    var text: String {
        get {
            if textSource == .fromHere {
                _auxText = textField.stringValue
            }
            return _auxText
        }
        set {
            _auxText = newValue
            textField.stringValue = _auxText
        }
    }
    var _auxText = ""
    
    var textSource: TextSource = .fromHere
    
    init(properLabel: String, typeString: String) {
        self.properLabel = properLabel
        self.typeString = typeString
        buildView()
    }
    
    func buildView() {
        
        var controls = [NSView]()
        
        textField = NSTextField()
        // textField.lineBreakMode =  NSLineBreakMode.byCharWrapping
        // textField.maximumNumberOfLines = 3
        // if let cell = textField.cell {
            // cell.truncatesLastVisibleLine = true
        // }
        
        controls.append(textField)
        
        let editTitle = appPrefsCocoa.makeUserAttributedString(text: "Edit", usage: .text)
        editButton = NSButton(title: "Edit", target: self, action: #selector(editButtonClicked))
        editButton.attributedTitle = editTitle
        controls.append(editButton)
        
        stack = NSStackView(views: controls)
        stack.orientation = .horizontal
        
        appPrefsCocoa.setTextEditingFont(object: textField)
        
    }
    
    @objc func editButtonClicked() {
        if let auxWC = self.auxStoryboard.instantiateController(withIdentifier: "auxTextWC") as? AuxTextEditWindowController {
            auxWC.shouldCascadeWindows = true
            auxWC.showWindow(self)
            if let vc = auxWC.contentViewController as? AuxTextEditViewController {
                vc.tailorViewFor(properLabel: properLabel, typeString: typeString)
                vc.setText(text)
                vc.auxTextView = self
                textSource = .fromAux
                // textField.isEditable = false
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "AuxTextView",
                              level: .fault,
                              message: "Couldn't get an Auxiliary Text Edit Window Controller!")
        }
    }
    
    func setText(_ str: String) {
        text = str
    }
    
    func auxEditComplete() {
        textSource = .fromHere
    }
    
    enum TextSource {
        case fromHere
        case fromAux
    }
    
}

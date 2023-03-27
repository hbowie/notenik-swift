//
//  TextFormatView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/27/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class TextFormatView: MacEditView {
    
    var lister = NSPopUpButton()
    
    var view: NSView {
        return lister
    }
    
    init() {
        lister.addItem(withTitle: NotenikConstants.textFormatMarkdown)
        lister.addItem(withTitle: NotenikConstants.textFormatPlainText)
        lister.selectItem(at: 0)
    }
    
    var text: String {
        get {
            switch lister.indexOfSelectedItem {
            case 1:
                return NotenikConstants.textFormatTxt
            default:
                return NotenikConstants.textFormatMD
            }
        }
        set {
            let newCommon = StringUtils.toCommon(newValue)
            switch newCommon {
            case NotenikConstants.textFormatTxt:
                lister.selectItem(at: 1)
            case NotenikConstants.textFormatPlainTextCommon:
                lister.selectItem(at: 1)
            default:
                lister.selectItem(at: 0)
            }
        }
    }
}

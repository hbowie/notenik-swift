//
//  ImageNameView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/9/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ImageNameView: MacEditView {
    
    let noFileSelected = " --- No File Selected --- "
    
    var lister = NSPopUpButton()
    
    var view: NSView {
        return lister
    }
    
    var text: String {
        get {
            if let selected = lister.titleOfSelectedItem {
                if lister.indexOfSelectedItem > 0 {
                    return selected
                }
            }
            return ""
        }
        set {
            let newLower = newValue.lowercased()
            var i = 0
            while i < lister.itemArray.count {
                if let item = lister.item(at: i) {
                    if item.title.lowercased().contains(newLower) {
                        lister.selectItem(at: i)
                        return
                    }
                }
                i += 1
            }
        }
    }
    
    
    init() {
        lister.addItem(withTitle: noFileSelected)
    }
    
    func customizeForNote(_ note: Note) {
        lister.removeAllItems()
        lister.addItem(withTitle: noFileSelected)
        for attachment in note.attachments {
            switch attachment.ext {
            case ".jpg", ".png", ".gif":
                lister.addItem(withTitle: attachment.suffix)
            default:
                continue
            }
        }
    }
}

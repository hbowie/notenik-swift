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

import NotenikUtils

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
            
            // Look for exact match
            var i = 0
            while i < lister.itemArray.count {
                if let item = lister.item(at: i) {
                    if item.title == newValue {
                        lister.selectItem(at: i)
                        return
                    }
                }
                i += 1
            }
            
            // Look for close match
            let newCommon = StringUtils.toCommon(newValue)
            i = 0
            while i < lister.itemArray.count {
                if let item = lister.item(at: i) {
                    let itemCommon = StringUtils.toCommon(item.title)
                    if itemCommon == newCommon {
                        lister.selectItem(at: i)
                        return
                    }
                }
                i += 1
            }
            
            // Look for contains
            i = 0
            while i < lister.itemArray.count {
                if let item = lister.item(at: i) {
                    let itemCommon = StringUtils.toCommon(item.title)
                    if itemCommon.contains(newCommon) {
                        lister.selectItem(at: i)
                        return
                    }
                }
                i += 1
            }
            
            if lister.itemArray.count > 0 {
                lister.selectItem(at: 0)
            }
        }
    }
    
    
    init() {
        lister.addItem(withTitle: noFileSelected)
    }
    
    /// Update attachments list with latest attachments.
    /// - Parameter note: The note being edited.
    func customizeForNote(_ note: Note) {
        lister.removeAllItems()
        lister.addItem(withTitle: noFileSelected)
        for attachment in note.attachments {
            if attachment.ext.isImage {
                lister.addItem(withTitle: attachment.suffix)
            }
        }
    }
    
}

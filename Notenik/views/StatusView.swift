//
//  StatusView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/16/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class StatusView: MacEditView {
    
    var config: StatusValueConfig!
    // var menu: NSPopUpButton!
    var combo: NSComboBox!
    
    var view: NSView {
        return combo
    }
    
    var text: String {
        get {
            return config.normalize(str: combo.stringValue, withDigit: true) 
            //if menu.titleOfSelectedItem != nil {
            //    return config.getFullString(fromLabel: menu.titleOfSelectedItem!)
            // } else {
            //    return ""
            // }
        }
        set {
            if let configIndex = config.getIndexFor(str: newValue) {
                let comboItem = config.get(configIndex)
                combo.selectItem(withObjectValue: comboItem)
            } else {
                combo.stringValue = newValue
            }
        }
    }
    
    init(config: StatusValueConfig) {
        self.config = config
        buildView()
    }
    
    func buildView() {
        
        // Set up the Menu
        combo = NSComboBox()
        // menu = NSPopUpButton()
        for option in config.statusOptions {
            if !option.isEmpty {
                combo.addItem(withObjectValue: option)
                // let menuItem = combo.item(at: combo.numberOfItems - 1)
                // menuItem!.attributedTitle = AppPrefsCocoa.shared.makeUserAttributedString(text: option)
            }
        }
        // AppPrefsCocoa.shared.setRegularFont(object: combo!.menu!)
    }
    
    /// Close the note by selecting the last status value in the list
    func close() {
        combo.selectItem(at: (combo.numberOfItems - 1))
    }
}

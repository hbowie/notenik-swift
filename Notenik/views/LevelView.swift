//
//  LevelView.swift
//  Notenik
//
//  Created by Herb Bowie on 6/4/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// A UI representation of a Level field.
class LevelView: MacEditView {
    
    var config: IntWithLabelConfig!
    var menu:   NSPopUpButton!
    
    var view: NSView {
        return menu
    }
    
    var text: String {
        get {
            if menu.titleOfSelectedItem != nil {
                return config.intWithLabel(forIntOrLabel: menu.titleOfSelectedItem!)
            } else {
                return ""
            }
        }
        set {
            let configIndex = config.get(newValue)
            let title = config.intWithLabel(forInt: configIndex)
            menu.selectItem(withTitle: title)
        }
    }
    
    init(config: IntWithLabelConfig) {
        self.config = config
        buildView()
    }
    
    func buildView() {
        
        // Set up the Menu
        menu = NSPopUpButton()
        for index in config.low...config.high {
            let intWithLabel = config.intWithLabel(forInt: index)
            menu.addItem(withTitle: intWithLabel)
            let menuItem = menu.item(at: menu.numberOfItems - 1)
            menuItem!.attributedTitle = AppPrefsCocoa.shared.makeUserAttributedString(text: intWithLabel, usage: .text)
        }
        AppPrefsCocoa.shared.setTextEditingFont(object: menu!.menu!)
    }

}

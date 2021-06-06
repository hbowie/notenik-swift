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

class LevelView: MacEditView {
    
    var config: IntWithLabelConfig!
    var menu:   NSPopUpButton!
    
    var view: NSView {
        return menu
    }
    
    var text: String {
        get {
            if menu.titleOfSelectedItem != nil {
                return config.intWithLabel(forLabel: menu.titleOfSelectedItem!)
            } else {
                return ""
            }
        }
        set {
            let configIndex = config.get(newValue)
            let title = config.label(forInt: configIndex)
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
        for label in config.labels {
            if label.count > 0 {
                menu.addItem(withTitle: label)
                let menuItem = menu.item(at: menu.numberOfItems - 1)
                menuItem!.attributedTitle = AppPrefsCocoa.shared.makeUserAttributedString(text: label)
            }
        }
        AppPrefsCocoa.shared.setRegularFont(object: menu!.menu!)
    }

}

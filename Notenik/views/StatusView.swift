//
//  StatusView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/16/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class StatusView: CocoaEditView {
    
    var config: StatusValueConfig!
    var menu: NSPopUpButton!
    
    var view: NSView {
        return menu
    }
    
    var text: String {
        get {
            if menu.titleOfSelectedItem != nil {
                return config.getFullString(fromLabel: menu.titleOfSelectedItem!)
            } else {
                return ""
            }
        }
        set {
            let configIndex = config.get(newValue)
            let title = config.get(configIndex)
            menu.selectItem(withTitle: title)
        }
    }
    
    init(config: StatusValueConfig) {
        self.config = config
        buildView()
    }
    
    func buildView() {
        
        // Set up the Menu
        menu = NSPopUpButton()
        for option in config.statusOptions {
            if option.count > 0 {
                menu.addItem(withTitle: option)
            }
        }
    }
}
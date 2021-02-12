//
//  NewCollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/7/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Controls a window used to guide the user through the steps of creating a new Collection of Notes. 
class NewCollectionWindowController: NSWindowController {
    
    var tabsVC: NewCollectionViewController!

    override func windowDidLoad() {
        super.windowDidLoad()
        tabsVC = (self.contentViewController as! NewCollectionViewController)
        tabsVC.wc = self
    }

}

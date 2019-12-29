//
//  DisplayPrefsWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class DisplayPrefsWindowController: NSWindowController {
    
    var displayPrefsViewController: DisplayPrefsViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is DisplayPrefsViewController {
            displayPrefsViewController = contentViewController as? DisplayPrefsViewController
            displayPrefsViewController!.window = self
        }
    }

}

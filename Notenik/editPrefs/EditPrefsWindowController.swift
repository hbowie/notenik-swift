//
//  EditPrefsWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/20/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class EditPrefsWindowController: NSWindowController {
    
    var editPrefsViewController: EditPrefsViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is EditPrefsViewController {
            editPrefsViewController = contentViewController as? EditPrefsViewController
            editPrefsViewController!.window = self
        }
    }

}

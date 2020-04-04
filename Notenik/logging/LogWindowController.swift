//
//  LogWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 3/28/19.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

class LogWindowController: NSWindowController {
    
    var logViewController: LogViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is LogViewController {
            logViewController = contentViewController as? LogViewController
            logViewController!.setText(logText: Logger.shared.log)
        }
    }

}

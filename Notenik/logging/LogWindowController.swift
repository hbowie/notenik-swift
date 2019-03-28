//
//  LogWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 3/28/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

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

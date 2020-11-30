//
//  NewICloudWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class NewICloudWindowController: NSWindowController {
    
    var newViewController: NewICloudViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is NewICloudViewController {
            newViewController = contentViewController as? NewICloudViewController
            newViewController!.window = self
        }
    }

}

//
//  AuxTextEditWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/14/23.
//  Copyright © 2023 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class AuxTextEditWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        if let vc = contentViewController as? AuxTextEditViewController {
            vc.window = self
        }
    }

}

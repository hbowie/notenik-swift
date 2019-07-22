//
//  AttachmentWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/21/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class AttachmentWindowController: NSWindowController {
    
    var vc: AttachmentViewController!

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is AttachmentViewController {
            vc = contentViewController as? AttachmentViewController
            vc.window = self
        }
    }

}

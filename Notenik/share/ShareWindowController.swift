//
//  ShareWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/15/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ShareWindowController: NSWindowController {
    
    var vc: ShareViewController!

    override func windowDidLoad() {
        super.windowDidLoad()
        vc = self.contentViewController as? ShareViewController
    }
    
    @IBAction func shareContentSelection(_ sender: Any) {
        vc.contentSelection()
    }
    
    @IBAction func shareFormatSelection(_ sender: Any) {
        vc.formatSelection()
    }
    
    @IBAction func shareDestinationSelection(_ sender: Any) {
        vc.destinationSelection()
    }

}

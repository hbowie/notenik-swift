//
//  QuickActionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/11/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class QuickActionWindowController: NSWindowController {
    
    var quickViewController: QuickActionViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is QuickActionViewController {
          quickViewController = contentViewController as? QuickActionViewController
          quickViewController!.window = self
        }
    }
    
    func restart() {
        if quickViewController != nil {
            quickViewController!.restart()
        }
    }
    
    var juggler: CollectionJuggler? {
        get {
            if quickViewController == nil {
                return nil
            } else {
                return quickViewController!.juggler
            }
        }
        set {
            if quickViewController != nil {
                quickViewController!.juggler = newValue
            }
        }
    }

}

//
//  NavigatorWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 9/10/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class NavigatorWindowController: NSWindowController {
    
    var navViewController: NavigatorViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is NavigatorViewController {
            navViewController = contentViewController as? NavigatorViewController
            navViewController!.window = self
        }
    }
    
    func reload() {
        if navViewController != nil {
            navViewController!.reload()
        }
    }
    
    var juggler: CollectionJuggler? {
        get {
            if navViewController == nil {
                return nil
            } else {
                return navViewController!.juggler
            }
        }
        set {
            if navViewController != nil {
                navViewController!.juggler = newValue
            }
        }
    }
}

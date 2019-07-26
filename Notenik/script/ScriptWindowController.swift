//
//  ScriptWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ScriptWindowController: NSWindowController {
    
    var scriptViewController: ScriptViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is ScriptViewController {
            scriptViewController = contentViewController as? ScriptViewController
            scriptViewController!.window = self
        }
    }
    
    func setScriptURL(_ scriptURL: URL) {
        if scriptViewController != nil {
            scriptViewController!.setScriptURL(scriptURL)
        }
    }

}

//
//  ExportWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/18/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ExportWindowController: NSWindowController {
    
    var exportViewController: ExportViewController?
    
    var io: NotenikIO? {
        get {
            return exportViewController?.io
        }
        set {
            if let vc = exportViewController {
                vc.io = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is ExportViewController {
            exportViewController = contentViewController as? ExportViewController
            exportViewController!.window = self
        }
    }

}

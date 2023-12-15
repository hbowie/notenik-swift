//
//  FieldRenameWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/11/23.
//  Copyright © 2023 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class FieldRenameWindowController: NSWindowController {
    
    var fieldRenameViewController: FieldRenameViewController?
    
    var io: NotenikIO? {
        get {
            return fieldRenameViewController?.io
        }
        set {
            if let vc = fieldRenameViewController {
                vc.io = newValue
            }
        }
    }
    
    var cwc: CollectionWindowController? {
        get {
            return fieldRenameViewController?.cwc
        }
        set {
            if let vc = fieldRenameViewController {
                vc.cwc = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is FieldRenameViewController {
            fieldRenameViewController = contentViewController as? FieldRenameViewController
            fieldRenameViewController!.window = self
        }
    }

}

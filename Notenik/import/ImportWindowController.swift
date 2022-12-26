//
//  ImportWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class ImportWindowController: NSWindowController {
    
    var importViewController: ImportViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is ImportViewController {
            importViewController = contentViewController as? ImportViewController
            importViewController!.window = self
        }
    }
    
    var collectionWC: CollectionWindowController? {
        get {
            return importViewController?.collectionWC
        }
        set {
            if let vc = importViewController {
                vc.collectionWC = newValue
            }
        }
    }
    
    var io: NotenikIO? {
        get {
            return importViewController?.io
        }
        set {
            if let vc = importViewController {
                vc.io = newValue
            }
        }
    }
    
    var parms: ImportParms {
        get {
            if let ip = importViewController?.importParms {
                return ip
            } else {
                return ImportParms()
            }
        }
        set {
            if let vc = importViewController {
                vc.importParms = newValue
            }
        }
    }

}

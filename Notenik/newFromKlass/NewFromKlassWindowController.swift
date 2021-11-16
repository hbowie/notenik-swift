//
//  NewFromClassWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/12/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa
import NotenikLib

class NewFromClassWindowController: NSWindowController {
    
    var newFromKlassViewController: NewFromKlassViewController?
    
    var noteIO: NotenikIO? {
        get {
            if newFromKlassViewController == nil {
                return nil
            } else {
                return newFromKlassViewController!.noteIO
            }
        }
        set {
            if newFromKlassViewController != nil {
                newFromKlassViewController!.noteIO = newValue
            }
        }
    }
    
    var collectionWC: CollectionWindowController? {
        get {
            if newFromKlassViewController == nil {
                return nil
            } else {
                return newFromKlassViewController!.collectionWC
            }
        }
        set {
            if newFromKlassViewController != nil {
                newFromKlassViewController!.collectionWC = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if let vc = contentViewController as? NewFromKlassViewController {
            newFromKlassViewController = vc
            vc.window = self
        }
    }

}

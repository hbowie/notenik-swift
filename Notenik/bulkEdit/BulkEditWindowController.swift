//
//  BulkEditWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/26/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class BulkEditWindowController: NSWindowController {
    
    var bulkEditViewController: BulkEditViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is BulkEditViewController {
            bulkEditViewController = contentViewController as? BulkEditViewController
            bulkEditViewController!.window = self
        }
    }
    
    func passRequestInfo(io: NotenikIO, collectionWC: CollectionWindowController, selNotes: [Note]) {
        bulkEditViewController!.passRequestInfo(io: io, collectionWC: collectionWC, selNotes: selNotes)
    }

}

//
//  SeqModWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class SeqModWindowController: NSWindowController {
    
    var viewController: SeqModViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if let vc = contentViewController as? SeqModViewController {
            viewController = vc
            vc.window = self
        }
    }
    
    var noteIO: NotenikIO? {
        get {
            if viewController == nil {
                return nil
            } else {
                return viewController!.noteIO
            }
        }
        set {
            if viewController != nil {
                viewController!.noteIO = newValue
            }
        }
    }
    
    var collectionWC: CollectionWindowController? {
        get {
            if viewController == nil {
                return nil
            } else {
                return viewController!.collectionWC
            }
        }
        set {
            if viewController != nil {
                viewController!.collectionWC = newValue
            }
        }
    }
    
    func setRange(startingRow: Int, endingRow: Int) {
        if viewController != nil {
            viewController!.setRange(startingRow: startingRow, endingRow: endingRow)
        }
    }

}

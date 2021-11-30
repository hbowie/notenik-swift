//
//  NewWithOptionsWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/12/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa
import NotenikLib

class NewWithOptionsWindowController: NSWindowController {
    
    var newWithOptionsViewController: NewWithOptionsViewController?
    
    var noteIO: NotenikIO? {
        get {
            if newWithOptionsViewController == nil {
                return nil
            } else {
                return newWithOptionsViewController!.noteIO
            }
        }
        set {
            if newWithOptionsViewController != nil {
                newWithOptionsViewController!.noteIO = newValue
            }
        }
    }
    
    var collectionWC: CollectionWindowController? {
        get {
            if newWithOptionsViewController == nil {
                return nil
            } else {
                return newWithOptionsViewController!.collectionWC
            }
        }
        set {
            if newWithOptionsViewController != nil {
                newWithOptionsViewController!.collectionWC = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        if let vc = contentViewController as? NewWithOptionsViewController {
            newWithOptionsViewController = vc
            vc.window = self
        }
    }
    
    func setCurrentNote(_ note: Note) {
        if newWithOptionsViewController != nil {
            newWithOptionsViewController!.setCurrentNote(note)
        }
    }
    
    public static func checkEligibility(collection: NoteCollection) -> String {
        guard (collection.klassFieldDef != nil
               && collection.klassDefs.count > 0)
                || collection.levelFieldDef != nil
                || collection.seqFieldDef != nil else {
            return "Collection does not define Class templates, or a Level field, or a Seq field"
        }
        return ""
    }

}

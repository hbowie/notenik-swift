//
//  MicroBlogWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/25/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class MicroBlogWindowController: NSWindowController {
    
    var info =    MicroBlogInfo()
    var win:      NSWindow?
    var vc:       MicroBlogViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        guard window != nil else { return }
        win = window!
        guard contentViewController != nil else { return }
        guard contentViewController! is MicroBlogViewController else { return }
        vc = contentViewController! as? MicroBlogViewController
        vc!.wc = self
        vc!.info = info
    }
    
    var note: Note? {
        get {
            return info.note
        }
        set {
            info.note = newValue
            if vc != nil {
                vc!.refreshNote()
            }
        }
    }

}

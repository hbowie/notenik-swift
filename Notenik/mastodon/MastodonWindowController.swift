//
//  MastodonWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class MastodonWindowController: NSWindowController {
    
    let info     = MastodonInfo.shared
    var win:       NSWindow!
    var vc:        MastodonViewController!
    var loadOK   = false
    
    override func windowWillLoad() {
        super.windowWillLoad()
        // mediumInt = MediumIntegrator(ui: self, info: info)

    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard window != nil else { return }
        win = window!
        guard contentViewController != nil else { return }
        guard contentViewController! is MastodonViewController else { return }
        vc = contentViewController! as? MastodonViewController
        vc.wc = self
        vc.window = win
        loadOK = true
    }
    
    var note: Note? {
        get {
            return info.note
        }
        set {
            info.note = newValue
        }
    }
    


}

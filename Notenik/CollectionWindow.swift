//
//  CollectionWindow.swift
//  Notenik
//
//  Created by Herb Bowie on 4/13/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class CollectionWindow: NSWindow {
    
    var io: NotenikIO?
    
    override func close() {
        if io != nil {
            io?.closeCollection()
        }
        if let wc = self.windowController as? CollectionWindowController {
            wc.windowWillClose()
        }
        super.close()
    }

}

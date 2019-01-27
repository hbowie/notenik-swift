//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class CollectionWindowController: NSWindowController {
    
    var io: NotenikIO = FileIO()
    var myVC: ViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        print("Collection Window Controller did load!")
        // myVC = window!.contentViewController as! ViewController
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}

//
//  NoteSplitViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/10/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class NoteSplitViewController: NSSplitViewController {
    
    var note: Note?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func shareClicked(_ sender: NSView) {
        guard let noteToShare = note else {
            return
        }
        let writer = BigStringWriter()
        let maker = NoteLineMaker(writer: writer)
        let fieldsWritten = maker.putNote(noteToShare)
        if fieldsWritten > 0 {
            let stringToShare = NSString(string: writer.bigString)
            let picker = NSSharingServicePicker(items: [stringToShare])
            picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
        }
    }
    
    func select(note: Note) {
        self.note = note
    }
    
}
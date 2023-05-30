//
//  SeqModViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/20/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class SeqModViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var collectionWC: CollectionWindowController?
    var window: SeqModWindowController?
    
    var io: NotenikIO?
    var collection: NoteCollection?
    var startingRow: Int = 0
    var endingRow: Int = 0
    
    @IBOutlet var rangeToRenumber: NSTextField!
    @IBOutlet var newStartingSeq: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    var noteIO: NotenikIO? {
        get {
            return io
        }
        set {
            io = newValue
            collection = io?.collection
        }
    }
    
    func setRange(startingRow: Int, endingRow: Int) {
        self.startingRow = startingRow
        self.endingRow = endingRow
        let startingNote = io!.getNote(at: startingRow)
        let endingNote = io!.getNote(at: endingRow)
        rangeToRenumber.stringValue = "\(startingNote!.seq) -> \(endingNote!.seq)"
        newStartingSeq.stringValue = startingNote!.seq.value
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        window!.close()
    }
    
    @IBAction func ok(_ sender: Any) {

        if let sequencer = Sequencer(io: io!) {
            let modStartingNote = sequencer.renumberRange(startingRow: startingRow, endingRow: endingRow, newSeqValue: newStartingSeq.stringValue)
            collectionWC!.seqModified(modStartingNote: modStartingNote, rowCount: 1)
        }
        application.stopModal(withCode: .OK)
        window!.close()
    }
    
}

//
//  NoteListViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class NoteListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
   
    @IBOutlet var tableView: NSTableView!
    
    var window: CollectionWindowController? {
        get {
            return collectionWindowController
        }
        set {
            collectionWindowController = newValue
        }
    }
    
    var io: NotenikIO? {
        get {
            return notenikIO
        }
        set {
            notenikIO = newValue
            guard notenikIO != nil && notenikIO!.collection != nil else {
                return
            }
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let notesCount = notenikIO?.notesCount {
            return notesCount
        } else {
            return 0
        }
    }
    
    /// Supply the value for a particular cell in the table.
    ///
    /// - Parameters:
    ///   - tableView: A Table view for the table.
    ///   - tableColumn: A description of the desired column.
    ///   - row: An index pointing to the desired row of the table.
    /// - Returns: The Cell View with the appropriate value set.
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        // Try to get the appropriate cell view
        guard let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        
        if let note = notenikIO?.getNote(at: row) {
            if tableColumn?.title == "Title" {
                cellView.textField?.stringValue = note.title.value
            } else if tableColumn?.title == "Seq" {
                cellView.textField?.stringValue = note.seq.value
            } else if tableColumn?.title == "X" {
                cellView.textField?.stringValue = note.status.doneX(config: note.collection.statusConfig)
            } else if tableColumn?.title == "Date" {
                cellView.textField?.stringValue = note.date.value
            }
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 else {
            return
        }
        if let note = notenikIO?.getNote(at: row) {
            if collectionWindowController != nil {
                collectionWindowController!.select(note: note)
            }
        }
    }
    
}

//
//  NoteListViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class NoteListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var tableView: NSTableView!
    
    var io: NotenikIO = FileIO()
    var collection: NoteCollection?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var provider = io.getProvider()
        
        var realm = Realm(provider: provider)
        realm.name = "Herb Bowie"
        realm.path = ""
        
        let path = Bundle.main.resourcePath! + "/notenik-swift-intro"
        
        collection = io.openCollection(realm: realm, collectionPath: path)
        io.sortParm = .title
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if collection == nil {
            self.view.window?.title = "Current Collection"
        } else if collection?.title != "" {
            self.view.window?.title = collection!.title
        } else {
            self.view.window?.title = collection!.path
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return io.notesCount
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
        
        let note = io.getNote(at: row)
        
        if note != nil {
            if tableColumn?.title == "Title" {
                cellView.textField?.stringValue = note!.title.value
            } else if tableColumn?.title == "Seq" {
                cellView.textField?.stringValue = note!.seq.value
            } else if tableColumn?.title == "X" {
                cellView.textField?.stringValue = note!.status.doneX(config: note!.collection.statusConfig)
            } else if tableColumn?.title == "Date" {
                cellView.textField?.stringValue = note!.date.value
            }
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row != -1 else {
            return
        }
        let note = io.getNote(at: row)
        guard note != nil else {
            return
        }
        guard let splitVC = parent as? NSSplitViewController else {
            return
        }
        if let displayVC = splitVC.children[1] as? NoteDisplayViewController {
            displayVC.noteSelected(note!)
        }
    }
    
}

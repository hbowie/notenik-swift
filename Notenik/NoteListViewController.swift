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
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        
        let note = io.getNote(at: row)
        if note != nil {
            cellView.textField?.stringValue = note!.title.value
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

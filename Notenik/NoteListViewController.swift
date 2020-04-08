//
//  NoteListViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
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
            guard notenikIO != nil && notenikIO!.collection != nil else { return }
            setSortParm(notenikIO!.collection!.sortParm)
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
    
    /// Reload the Table's Data.
    func reload() {
        tableView.reloadData()
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
        guard let anyView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) else { return nil }
        guard let cellView = anyView as? NSTableCellView else { return nil }
        
        if let note = notenikIO?.getNote(at: row) {
            if tableColumn?.title == "Title" {
                cellView.textField?.stringValue = note.title.value
            } else if tableColumn?.title == "Seq" {
                cellView.textField?.stringValue = note.seq.value
            } else if tableColumn?.title == "X" {
                cellView.textField?.stringValue = note.doneXorT
            } else if tableColumn?.title == "Date" {
                cellView.textField?.stringValue = note.date.dMyDate
            } else if tableColumn?.title == "Author" {
                cellView.textField?.stringValue = note.creatorValue
            } else if tableColumn?.title == "Tags" {
                cellView.textField?.stringValue = note.tags.value
            } else if tableColumn?.title == "Stat" {
                cellView.textField?.stringValue = String(note.status.getInt())
            }
        }
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard collectionWindowController != nil && row >= 0 else { return }
        let outcome = collectionWindowController!.modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        if let (note, position) = notenikIO?.selectNote(at: row) {
            collectionWindowController!.select(note: note, position: position, source: NoteSelectionSource.list)
        }
    }
    
    func selectRow(index: Int) {
        let indexSet = IndexSet(integer: index)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
    
    @IBAction func scrollToSelected(_ sender: Any) {
        let selected = tableView.selectedRow
        tableView.scrollRowToVisible(selected)
    }
    
    func setSortParm(_ sortParm: NoteSortParm) {

        switch sortParm {
        case .title:
            addTitleColumn(at: 0)
            trimColumns(to: 1)
        case .seqPlusTitle:
            addSeqColumn(at: 0)
            addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .tasksByDate:
            addXColumn(at: 0)
            addDateColumn(at: 1)
            addSeqColumn(at: 2)
            addTitleColumn(at: 3)
            trimColumns(to: 4)
        case .tasksBySeq:
            addXColumn(at: 0)
            addSeqColumn(at: 1)
            addDateColumn(at: 2)
            addTitleColumn(at: 3)
            trimColumns(to: 4)
        case .tagsPlusTitle:
            addTagsColumn(at: 0)
            addStatusDigit(at: 1)
            addTitleColumn(at: 2)
        case .author:
            addAuthorColumn(at: 0)
            addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .custom:
            addTitleColumn(at: 0)
            trimColumns(to: 1)
        }
        tableView.reloadData()
    }
    
    func setSortDescending(_ descending: Bool) {
        tableView.reloadData()
    }
    
    func addTitleColumn(at desiredIndex: Int) {
        addColumn(title: "Title", strID: "title-column", at: desiredIndex, min: 200, width: 445, max: 1500)
    }
    
    func addSeqColumn(at desiredIndex: Int) {
        addColumn(title: "Seq", strID: "seq-column", at: desiredIndex, min: 50, width: 80, max: 250)
    }
    
    func addXColumn(at desiredIndex: Int) {
        addColumn(title: "X", strID: "x-column", at: desiredIndex, min: 12, width: 20, max: 50)
    }
    
    func addStatusDigit(at desiredIndex: Int) {
        addColumn(title: "Stat", strID: "status-digit-column", at: desiredIndex, min: 20, width: 30, max: 50)
    }
    
    func addDateColumn(at desiredIndex: Int) {
        addColumn(title: "Date", strID: "date-column", at: desiredIndex, min: 100, width: 120, max: 300)
    }
    
    func addAuthorColumn(at desiredIndex: Int) {
        addColumn(title: "Author", strID: "author-column", at: desiredIndex, min: 100, width: 200, max: 1000)
    }
    
    func addTagsColumn(at desiredIndex: Int) {
        addColumn(title: "Tags", strID: "tags-column", at: desiredIndex, min: 50, width: 100, max: 1200)
    }
    
    /// Add a column, or make sure it already exists, and position it appropriately.
    ///
    /// - Parameters:
    ///   - title: The title of the column.
    ///   - strID: The String used to identify the column in the UI.
    ///   - desiredIndex: The desired index position for the column.
    func addColumn(title: String, strID: String, at desiredIndex: Int, min: Int, width: Int, max: Int) {
        
        let id = NSUserInterfaceItemIdentifier(strID)
        var i = 0
        var existingIndex = -1
        while i < tableView.tableColumns.count && existingIndex < 0 {
            if tableView.tableColumns[i].title == title {
                existingIndex = i
            } else {
                i += 1
            }
        }
        var column: NSTableColumn?
        if existingIndex >= 0 && existingIndex != desiredIndex {
            tableView.moveColumn(existingIndex, toColumn: desiredIndex)
            column = tableView.tableColumns[desiredIndex]
        } else if existingIndex < 0 {
            column = NSTableColumn(identifier: id)
            column!.title = title
            let newIndex = tableView.tableColumns.count
            tableView.addTableColumn(column!)
            if newIndex != desiredIndex {
                tableView.moveColumn(newIndex, toColumn: desiredIndex)
            }
        }
        if column != nil {
            column!.minWidth = CGFloat(min)
            column!.width = CGFloat(width)
            column!.maxWidth = CGFloat(max)
        }
    }
    
    /// Trim the table view to only show the desired number of columns.
    ///
    /// - Parameter desiredNumberOfColumns: The number of columns to retain. 
    func trimColumns(to desiredNumberOfColumns: Int) {
        while tableView.tableColumns.count > desiredNumberOfColumns {
            let columntToRemove = tableView.tableColumns[tableView.tableColumns.count - 1]
            tableView.removeTableColumn(columntToRemove)
        }
    }
    
}

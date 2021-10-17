//
//  NoteListViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

class NoteListViewController:   NSViewController,
                                NSTableViewDataSource,
                                NSTableViewDelegate {

    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
   
    @IBOutlet var tableView: NSTableView!
    
    var shortcutMenu: NSMenu!
    var newChildSepIndex = -1
    var newChildIndex = -1
    
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
            modShortcutMenuForCollection()
        }
    }
    
    /// Initialization after the view loaded.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup for drag and drop.
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)
        tableView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeBookmark as String),
                                           NSPasteboard.PasteboardType(kUTTypeURL as String),
                                           NSPasteboard.PasteboardType.vCard,
                                           NSPasteboard.PasteboardType.string])
        
        tableView.target = self
        tableView.doubleAction = #selector(doubleClick(_:))
        
        // Setup the popup menu for rows in the list. 
        shortcutMenu = NSMenu()
        shortcutMenu.addItem(NSMenuItem(title: "Duplicate", action: #selector(duplicateItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Launch Link", action: #selector(launchLinkForItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Share...", action: #selector(shareItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Copy Notenik URL", action: #selector(copyItemInternalURL(_:)), keyEquivalent: ""))
        tableView.menu = shortcutMenu
    }
    
    func modShortcutMenuForCollection() {
        
        if newChildIndex >= 0 {
            shortcutMenu.removeItem(at: newChildIndex)
            newChildIndex = -1
        }
        if newChildSepIndex >= 0 {
            shortcutMenu.removeItem(at: newChildSepIndex)
            newChildSepIndex = -1
        }

        if notenikIO!.collection!.seqFieldDef != nil && notenikIO!.collection!.levelFieldDef != nil {
            newChildSepIndex = shortcutMenu.numberOfItems
            shortcutMenu.addItem(NSMenuItem.separator())
            newChildIndex = shortcutMenu.numberOfItems
            shortcutMenu.addItem(NSMenuItem(title: "New Child", action: #selector(newChildForItem(_:)), keyEquivalent: ""))
        }
    }
    
    @objc private func newChildForItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.newChild(parent: clickedNote)
    }
    
    /// Respond to a contextual menu selection to duplicate the clicked Note.
    @objc private func duplicateItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.duplicateNote(startingNote: clickedNote)
    }
    
    /// Respond to a contextual menu selection to increment the clicked Note.
    @objc private func incrementItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.incrementNote(clickedNote)
    }
    
    /// Respond to a contextual menu selection to launch a link for the clicked Note.
    @objc private func launchLinkForItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.launchLink(for: clickedNote)
    }
    
    /// Respond to a contextual menu selection to launch a link for the clicked Note.
    @objc private func shareItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.shareNote(clickedNote)
    }
    
    /// Respond to a request to copy a note's internal url to the clipboard.
    @objc private func copyItemInternalURL(_ sender: AnyObject) {
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        var str = "notenik://open?"
        if collection.shortcut.count > 0 {
            str.append("shortcut=\(collection.shortcut)")
        } else {
            let folderURL = URL(fileURLWithPath: collection.fullPath)
            let encodedPath = String(folderURL.absoluteString.dropFirst(7))
            str.append("path=\(encodedPath)")
        }
        str.append("&id=\(clickedNote.id)")
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// Respond to double-click.
    @objc func doubleClick(_ sender: Any) {
        guard collectionWindowController != nil else { return }
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.launchLink(for: clickedNote)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Drag and Drop logic.
    //
    // -----------------------------------------------------------
    
    /// Write a selected item to the pasteboard.
    func tableView(_ tableView: NSTableView,
                   pasteboardWriterForRow row: Int)
                        -> NSPasteboardWriting? {
        if let selectedNote = notenikIO?.getNote(at: row) {
            let maker = NoteLineMaker()
            let _ = maker.putNote(selectedNote)
            var str = ""
            if let writer = maker.writer as? BigStringWriter {
                str = writer.bigString
            }
            return str as NSString
        }
        return nil
    }
    
    /// Validate a proposed drop operation.
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation)
                    -> NSDragOperation {
        return .copy
    }
    
    /// Process one or more dropped items.
    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation)
                    -> Bool {
        
        guard collectionWindowController != nil else { return false }
        
        let pasteboard = info.draggingPasteboard
        
        let items = pasteboard.pasteboardItems
        var notesPasted = 0
        
        if items != nil && items!.count > 0 {
            notesPasted = collectionWindowController!.pasteItems(items!, row: row, dropOperation: dropOperation)
        }
        
        guard notesPasted == 0 else { return true }
        
        let filePromises = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil)
        if filePromises != nil {
            collectionWindowController!.pastePromises(filePromises!)
            return true
        }
        
        return true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    /// Reload the Table's Data.
    func reload() {
        tableView.reloadData()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Methods for NSTableViewDataSource
    //
    // -----------------------------------------------------------
    
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
        guard let anyView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) else { return nil }
        guard let cellView = anyView as? NSTableCellView else { return nil }
        
        if let note = notenikIO?.getNote(at: row) {
            if tableColumn?.title == "Title" ||
                    tableColumn?.title == note.collection.titleFieldDef.fieldLabel.properForm {
                let title = note.title.value
                var displayValue = ""
                if let collection = notenikIO?.collection {
                    if collection.sortParm == .seqPlusTitle {
                        if note.hasLevel() {
                            let config = collection.levelConfig
                            let levelValue = note.level
                            let level = levelValue.getInt()
                            let indent = level - config.low
                            if indent > 0 {
                                displayValue = String(repeating: "  ", count: indent)
                            }
                        } 
                    }
                }
                displayValue.append(title)
                cellView.textField?.stringValue = displayValue
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
            } else if tableColumn?.title == "Date Added" {
                cellView.textField?.stringValue = note.dateAddedValue
            } else if notenikIO != nil && notenikIO!.collection != nil {
                if tableColumn?.title == notenikIO!.collection!.titleFieldDef.fieldLabel.properForm {
                    cellView.textField?.stringValue = note.title.value
                } else if tableColumn?.title == notenikIO!.collection!.tagsFieldDef.fieldLabel.properForm {
                    cellView.textField?.stringValue = note.tags.value
                } else if tableColumn?.title == notenikIO!.collection!.dateFieldDef.fieldLabel.properForm {
                    cellView.textField?.stringValue = note.date.dMyDate
                } else if notenikIO!.collection!.seqFieldDef != nil && tableColumn?.title == notenikIO!.collection!.seqFieldDef!.fieldLabel.properForm {
                    cellView.textField?.stringValue = note.seq.value
                } else if tableColumn?.title == notenikIO!.collection!.creatorFieldDef.fieldLabel.properForm {
                    cellView.textField?.stringValue = note.creatorValue
                }
            }
        }
        
        return cellView
    }
    
    /// Respond to a user selection of a row in the table.
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard collectionWindowController != nil && row >= 0 else { return }
        let outcome = collectionWindowController!.modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        if let (note, position) = notenikIO?.selectNote(at: row) {
            collectionWindowController!.select(note: note, position: position, source: NoteSelectionSource.list)
        }
    }
    
    func selectRow(index: Int, andScroll: Bool = false) {
        let indexSet = IndexSet(integer: index)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        if andScroll {
            scrollToSelectedRow()
        }
    }
    
    func scrollToSelectedRow() {
        let selected = tableView.selectedRow
        tableView.scrollRowToVisible(selected)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Change the Table View for different Sort selections.
    //
    // -----------------------------------------------------------
    
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
        case .tagsPlusSeq:
            addTagsColumn(at: 0)
            addSeqColumn(at: 1)
            addTitleColumn(at: 2)
        case .author:
            addAuthorColumn(at: 0)
            addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .dateAdded:
            addDateAddedColumn(at: 0)
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
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Title", strID: "title-column", at: desiredIndex, min: 200, width: 445, max: 1500)
            return
        }
        addColumn(title: collection.titleFieldDef.fieldLabel.properForm,
                  strID: "title-column",
                  at: desiredIndex, min: 200, width: 445, max: 1500)
    }
    
    func addSeqColumn(at desiredIndex: Int) {
        if notenikIO != nil
            && notenikIO!.collection != nil
            && notenikIO!.collection!.seqFieldDef != nil {
            addColumn(title: notenikIO!.collection!.seqFieldDef!.fieldLabel.properForm,
                      strID: "seq-column",
                      at: desiredIndex, min: 50, width: 80, max: 250)
        } else {
            addColumn(title: "Seq", strID: "seq-column", at: desiredIndex, min: 50, width: 80, max: 250)
        }
    }
    
    func addXColumn(at desiredIndex: Int) {
        addColumn(title: "X", strID: "x-column", at: desiredIndex, min: 12, width: 20, max: 50)
    }
    
    func addStatusDigit(at desiredIndex: Int) {
        addColumn(title: "Stat", strID: "status-digit-column", at: desiredIndex, min: 20, width: 30, max: 50)
    }
    
    func addDateColumn(at desiredIndex: Int) {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Date", strID: "date-column", at: desiredIndex, min: 200, width: 445, max: 1500)
            return
        }
        addColumn(title: collection.dateFieldDef.fieldLabel.properForm,
                  strID: "date-column",
                  at: desiredIndex, min: 100, width: 120, max: 300)
    }
    
    func addAuthorColumn(at desiredIndex: Int) {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Author", strID: "author-column", at: desiredIndex, min: 100, width: 200, max: 1000)
            return
        }
        addColumn(title: collection.creatorFieldDef.fieldLabel.properForm,
                  strID: "author-column",
                  at: desiredIndex, min: 100, width: 200, max: 1000)
    }
    
    func addTagsColumn(at desiredIndex: Int) {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Tags", strID: "tags-column", at: desiredIndex, min: 50, width: 100, max: 1200)
            return
        }
        addColumn(title: collection.tagsFieldDef.fieldLabel.properForm,
                  strID: "tags-column",
                  at: desiredIndex, min: 50, width: 100, max: 1200)
    }
    
    func addDateAddedColumn(at desiredIndex: Int) {
        addColumn(title: "Date Added", strID: "date-added-column", at: desiredIndex, min: 100, width: 180, max: 250)
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

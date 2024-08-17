//
//  NoteListViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

class NoteListViewController:   NSViewController,
                                NSTableViewDataSource,
                                NSTableViewDelegate,
                                CollectionView {
    
    let defaults = UserDefaults.standard

    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    
    var monoFont: NSFont?
    var monoDigitFont: NSFont?
    
    var userFont: NSFont?
    var userFontName = ""
   
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var scrollView: NSScrollView!
    
    var shortcutMenu: NSMenu!
    var newChildIndex = -1
    var newWithOptionsIndex = -1
    var seqModIndex = -1
    
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
        
        adjustFonts()
        
        adjustScroller()
        
        // Setup for drag and drop.
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)
        tableView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeBookmark as String),
                                           NSPasteboard.PasteboardType(kUTTypeURL as String),
                                           NSPasteboard.PasteboardType(kUTTypeVCard as String),
                                           NSPasteboard.PasteboardType.string])
        
        tableView.target = self
        tableView.doubleAction = #selector(doubleClick(_:))
        
        // Setup the popup menu for rows in the list. 
        shortcutMenu = NSMenu()
        shortcutMenu.addItem(NSMenuItem(title: "Show in Finder", action: #selector(showInFinder(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Launch Link", action: #selector(launchLinkForItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Share...", action: #selector(shareItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Copy Notenik URL", action: #selector(copyItemInternalURL(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Copy Title", action: #selector(copyItemTitle(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Copy Timestamp", action: #selector(copyItemTimestamp(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Export to iCal", action: #selector(exportToICal(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Bulk Edit...", action: #selector(bulkEdit(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem.separator())
        shortcutMenu.addItem(NSMenuItem(title: "Duplicate", action: #selector(duplicateItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Delete Range...", action: #selector(deleteNotes(_:)), keyEquivalent: ""))
        tableView.menu = shortcutMenu
    }
    
    func adjustFonts() {
        if #available(macOS 10.15, *) {
            monoFont = NSFont.monospacedSystemFont(ofSize: 13.0, weight: NSFont.Weight.regular)
        }
        monoDigitFont = NSFont.monospacedDigitSystemFont(ofSize: 13.0, weight: NSFont.Weight.regular)
        
        userFont = nil
        var listFontMsg = ""
        var rowHeight: CGFloat = 17.0
        if let userFontName = defaults.string(forKey: "list-display-font") {
            listFontMsg = "List Tab Font Request: name = \(userFontName)"
            if !userFontName.isEmpty && !userFontName.lowercased().contains("system font") {
                if let userFontSize = defaults.string(forKey: "list-display-size") {
                    listFontMsg.append(", font size = \(userFontSize)")
                    if let doubleValue = Double(userFontSize) {
                        let cgFloat = CGFloat(doubleValue)
                        rowHeight = cgFloat * 1.3
                        userFont = NSFont(name: userFontName, size: cgFloat)
                    } else {
                        listFontMsg.append(" | Could not convert \(userFontSize) to a double")
                    }
                } else {
                    listFontMsg.append(" | font size not available")
                }
            }
        } else {
            listFontMsg = "List User font not available"
        }
        if userFont == nil {
            tableView.rowHeight = CGFloat(17.0)
            tableView.rowSizeStyle = .custom
        } else {
            tableView.rowHeight = rowHeight
            tableView.rowSizeStyle = .custom
        }
        /*
        if !listFontMsg.isEmpty {
            logInfo(msg: listFontMsg)
        } */
    }
    
    func modShortcutMenuForCollection() {
        
        if newWithOptionsIndex >= 0 {
            if shortcutMenu.numberOfItems > newWithOptionsIndex {
                shortcutMenu.removeItem(at: newWithOptionsIndex)
            }
            newWithOptionsIndex = -1
        }
        
        if newChildIndex >= 0 {
            if shortcutMenu.numberOfItems > newChildIndex {
                shortcutMenu.removeItem(at: newChildIndex)
            }
            newChildIndex = -1
        }
        
        if seqModIndex >= 0 {
            if shortcutMenu.numberOfItems > seqModIndex {
                shortcutMenu.removeItem(at: seqModIndex)
            }
            seqModIndex = -1
        }
        
        guard let collection = notenikIO?.collection else { return }
        
        if collection.seqFieldDef != nil
            && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) {
            seqModIndex = shortcutMenu.numberOfItems
            shortcutMenu.addItem(withTitle: "Modify Seq...", action: #selector(seqModify(_:)), keyEquivalent: "")
        }

        if collection.seqFieldDef != nil && collection.levelFieldDef != nil {
            newChildIndex = shortcutMenu.numberOfItems
            shortcutMenu.addItem(NSMenuItem(title: "New Child", action: #selector(newChildForItem(_:)), keyEquivalent: ""))
        }
        
        if (collection.klassFieldDef != nil
               && collection.klassDefs.count > 0)
                || collection.levelFieldDef != nil
                || collection.seqFieldDef != nil {
            newWithOptionsIndex = shortcutMenu.numberOfItems
            shortcutMenu.addItem(withTitle: "New with Options...", action: #selector(newWithOptions(_:)), keyEquivalent: "")
        }
    
    }
    
    @objc private func exportToICal(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        guard tableView.numberOfSelectedRows > 0 else { return }

        // Get the full range of selected notes.
        let (lowIndex, highIndex) = getRangeOfSelectedRows()
        guard lowIndex >= 0 else { return }
        // Make sure the user clicked somewhere within this range.
        if tableView.clickedRow > highIndex || tableView.clickedRow < lowIndex {
            return
        }
        
        collectionWindowController!.exportToICal(startingRow: lowIndex, endingRow: highIndex)
    }
    
    @objc private func deleteNotes(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        guard tableView.numberOfSelectedRows > 0 else { return }

        // Get the full range of selected notes.
        let (lowIndex, highIndex) = getRangeOfSelectedRows()
        guard lowIndex >= 0 else { return }
        // Make sure the user clicked somewhere within this range.
        if tableView.clickedRow > highIndex || tableView.clickedRow < lowIndex {
            return
        }
        
        collectionWindowController!.deleteRangeOfNotes(startingRow: lowIndex, endingRow: highIndex)
    }
    
    /// Modify the seq values for a range of notes.
    @objc private func seqModify(_ sender: AnyObject) {
 
        guard collectionWindowController != nil else { return }
        guard tableView.numberOfSelectedRows > 0 else { return }
        guard let collection = notenikIO?.collection else { return }
        
        guard collection.seqFieldDef != nil && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) else {
            return
        }

        // Get the full range of selected notes.
        let (lowIndex, highIndex) = getRangeOfSelectedRows()
        guard lowIndex >= 0 else { return }
        // Make sure the user clicked somewhere within this range.
        if tableView.clickedRow > highIndex || tableView.clickedRow < lowIndex {
            return 
        }
        
        collectionWindowController!.seqModify(startingRow: lowIndex, endingRow: highIndex)
    }
    
    /// Bulk edit a set of selected Notes. 
    @IBAction func bulkEdit(_ sender: Any) {
        guard let wc = collectionWindowController else { return }
        guard let io = notenikIO else { return }
        var selNotes: [Note] = []
        for index in tableView.selectedRowIndexes {
            if let selNote = io.getNote(at: index) {
                selNotes.append(selNote)
            }
        }
        wc.bulkEdit(notes: selNotes)
    }
    
    /// Launch a Note's Link
    @IBAction func launchLink(_ sender: Any) {
        for index in tableView.selectedRowIndexes {
            launchLinkForRow(index)
        }
    }
    
    /// Respond to a contextual menu selection to launch a link for the clicked Note.
    @objc private func launchLinkForItem(_ sender: AnyObject) {
       
        guard tableView.clickedRow >= 0 else { return }
        
        var clickedWithinSelected = false
        for index in tableView.selectedRowIndexes {
            if tableView.clickedRow == index {
                clickedWithinSelected = true
                break
            }
        }
        
        if clickedWithinSelected {
            for index in tableView.selectedRowIndexes {
                launchLinkForRow(index)
            }
        } else {
            launchLinkForRow(tableView.clickedRow)
        }

    }
    
    func launchLinkForRow(_ row: Int) {
        guard let wc = collectionWindowController else { return }
        guard let io = notenikIO else { return }
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        wc.launchLink(for: clickedNote)
    }
    
    /// Get a possible range of selected rows from the table view.
    /// - Returns: The first (lowest) row selected, and the highest row selected,
    /// or a pair of negative values is no valid selection.
    func getRangeOfSelectedRows() -> (Int, Int) {

        let selectedRow = tableView.selectedRow
        if selectedRow < 0 { return (-1, -1) }
        
        var lowIndex = selectedRow
        var highIndex = selectedRow
        
        var rowToTest = selectedRow - 1
        var stillSelected = true
        while rowToTest >= 0 && stillSelected {
            if tableView.isRowSelected(rowToTest) {
                lowIndex = rowToTest
                rowToTest -= 1
            } else {
                stillSelected = false
            }
        }
        
        rowToTest = tableView.selectedRow + 1
        stillSelected = true
        while rowToTest < tableView.numberOfRows && stillSelected {
            if tableView.isRowSelected(rowToTest) {
                highIndex = rowToTest
                rowToTest += 1
            } else {
                stillSelected = false
            }
        }
        
        return (lowIndex, highIndex)
    }
    
    func extendSelection(rowCount: Int) {
        let selectedRow = tableView.selectedRow
        var topRow = selectedRow + rowCount - 1
        if topRow >= tableView.numberOfRows {
            topRow = tableView.numberOfRows - 1
        }
        var selIx = selectedRow + 1
        while selIx <= topRow {
            let indexSet = IndexSet(integer: selIx)
            tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
            selIx += 1
        }
    }
    
    @objc private func newChildForItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.newChild(parent: clickedNote)
    }
    
    @objc private func newWithOptions(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        var clickedNote: Note?
        if row >= 0 {
            clickedNote = notenikIO!.getNote(at: row)
        }
        collectionWindowController!.newWithOptions(currentNote: clickedNote)
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
    @objc private func shareItem(_ sender: AnyObject) {
        guard collectionWindowController != nil else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = notenikIO?.getNote(at: row) else { return }
        collectionWindowController!.shareNote(clickedNote)
    }
    
    /// Respond to a request to copy a note's internal url to the clipboard.
    @objc private func copyItemTitle(_ sender: AnyObject) {
        guard let io = notenikIO else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        let str = clickedNote.noteID.getBasis()
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// Respond to a request to copy a note's internal url to the clipboard.
    @objc private func copyItemTimestamp(_ sender: AnyObject) {
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        let board = NSPasteboard.general
        board.clearContents()
        guard collection.hasTimestamp else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        let str = clickedNote.timestampAsString
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// Respond to a request to copy a note's internal url to the clipboard.
    @objc private func copyItemInternalURL(_ sender: AnyObject) {
        guard let io = notenikIO else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        let str = clickedNote.getNotenikLink(preferringTimestamp: false)
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        guard let io = notenikIO else { return }
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        guard let clickedNote = io.getNote(at: row) else { return }
        let folderPath = io.collection!.lib.getPath(type: .collection)
        let filePath = clickedNote.noteID.getFullPath(note: clickedNote)
        NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: folderPath)
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
            let _ = maker.putNote(selectedNote, includeAttachments: true)
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
        adjustFonts()
        if let collection = notenikIO?.collection {
            setSortParm(collection.sortParm)
        }
        adjustScroller()
        tableView.reloadData()
    }
    
    func adjustScroller() {
        scrollView.usesPredominantAxisScrolling = true
        switch AppPrefs.shared.horizontalListScrollBar {
        case "on":
            scrollView.hasHorizontalScroller = true
        case "off":
            scrollView.hasHorizontalScroller = false
        default:
            break
        }
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
            if !lnfCol1Title.isEmpty && lnfCol1Title == tableColumn?.title {
                modifyCellView(cellView: cellView, value: note.lastNameFirst)
            } else if tableColumn?.title == "Title" ||
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
                                displayValue = AppPrefs.shared.indentSpaces(level: indent)
                            }
                        }
                    }
                }
                displayValue.append(title)
                modifyCellView(cellView: cellView, value: displayValue)
            } else if tableColumn?.title == "Class" {
                modifyCellView(cellView: cellView, value: note.klass.value)
            } else if tableColumn?.title == NotenikConstants.folder {
                modifyCellView(cellView: cellView, value: note.folder.value)
            } else if tableColumn?.title == "Rank" {
                modifyCellView(cellView: cellView, value: note.rank.value)
            } else if tableColumn?.title == "Seq" {
                modifyCellView(cellView: cellView, value: note.seq.value, mono: true)
            } else if tableColumn?.title == "X" {
                modifyCellView(cellView: cellView, value: note.doneXorT)
            } else if tableColumn?.title == "Date" {
                modifyCellView(cellView: cellView, value: note.date.dMyW2Date, mono: true)
            } else if tableColumn?.title == "Author" {
                modifyCellView(cellView: cellView, value: note.creatorValue)
            } else if tableColumn?.title == "Tags" {
                modifyCellView(cellView: cellView, value: note.tags.value)
            } else if tableColumn?.title == "Stat" {
                modifyCellView(cellView: cellView, value: String(note.status.getInt()))
            } else if tableColumn?.title == "Person Name" {
                if notenikIO?.collection?.personDef != nil {
                    modifyCellView(cellView: cellView, value: note.person.value)
                } else {
                    modifyCellView(cellView: cellView, value: note.creatorValue)
                }
            } else if tableColumn?.title == "Date Added" {
                modifyCellView(cellView: cellView, value: note.dateAddedValue, mono: true)
            } else if tableColumn?.title == "Date Mod" {
                modifyCellView(cellView: cellView, value: note.dateModifiedValue, mono: true)
            } else if notenikIO != nil && notenikIO!.collection != nil {
                if tableColumn?.title == notenikIO!.collection!.titleFieldDef.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.title.value)
                } else if notenikIO!.collection!.rankFieldDef != nil && tableColumn?.title == notenikIO!.collection!.rankFieldDef!.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.rank.value)
                } else if tableColumn?.title == notenikIO!.collection!.tagsFieldDef.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.tags.value)
                } else if tableColumn?.title == notenikIO!.collection!.dateFieldDef.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.date.dMyDate)
                } else if notenikIO!.collection!.seqFieldDef != nil && tableColumn?.title == notenikIO!.collection!.seqFieldDef!.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.seq.value, mono: true)
                } else if tableColumn?.title == notenikIO!.collection!.creatorFieldDef.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.creatorValue)
                } else if notenikIO!.collection!.klassFieldDef != nil && tableColumn?.title == notenikIO!.collection!.klassFieldDef!.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.klass.value)
                } else if notenikIO!.collection!.personDef != nil && tableColumn?.title == notenikIO!.collection!.personDef!.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.person.value)
                } else if notenikIO!.collection!.folderFieldDef != nil && tableColumn?.title == notenikIO!.collection!.folderFieldDef?.fieldLabel.properForm {
                    modifyCellView(cellView: cellView, value: note.folder.value)
                }
            }
        }
        
        return cellView
    }
    
    func modifyCellView(cellView: NSTableCellView, value: String, mono: Bool = false) {
        
        if userFont != nil {
            cellView.textField?.font = userFont!
            cellView.rowSizeStyle = .custom
        } else if mono && monoFont != nil {
            cellView.textField?.font = monoFont!
            cellView.rowSizeStyle = .custom
        } else {
            cellView.textField?.font = monoDigitFont
            cellView.rowSizeStyle = .custom
        }
        cellView.textField?.stringValue = value
    }
    
    var checkForMods = true
    var programmaticSelection = false
    var lastRowSelected = 0
    
    /// Respond to a user selection of a row in the table.
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard checkForMods else { return }
        guard !programmaticSelection else { return }
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        guard coordinator != nil else { return }
        guard collectionWindowController != nil else { return }
        // let (outcome, _) = collectionWindowController!.modIfChanged()
        // guard outcome != modIfChangedOutcome.tryAgain else { return }
        // collectionWindowController!.applyCheckBoxUpdates()
        _ = coordinator!.focusOn(initViewID: viewID,
                             note: nil,
                             position: nil,
                             row: row,
                             searchPhrase: nil)
        // if let (note, position) = notenikIO?.selectNote(at: row) {
        //     collectionWindowController!.select(note: note, position: position, source: NoteSelectionSource.list)
        // }
        lastRowSelected = row
    }
    
    func selectRow(index: Int, andScroll: Bool = false, checkForMods: Bool) {
        programmaticSelection = true
        self.checkForMods = checkForMods
        let indexSet = IndexSet(integer: index)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        if andScroll {
            scrollToSelectedRow()
        }
        self.checkForMods = true
        programmaticSelection = false
    }
    
    func scrollToSelectedRow() {
        let selected = tableView.selectedRow
        var scrollRow = selected
        if selected > lastRowSelected {
            scrollRow = selected + 2
        } else if selected < lastRowSelected {
            scrollRow = selected - 2
        }
        if scrollRow >= tableView.numberOfRows {
            scrollRow = tableView.numberOfRows - 1
        }
        if scrollRow < 0 {
            scrollRow = 0
        }
        tableView.scrollRowToVisible(scrollRow)
        lastRowSelected = selected
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Change the Table View for different Sort selections.
    //
    // -----------------------------------------------------------
    
    var lnfCol1Title = ""
    
    func setSortParm(_ sortParm: NoteSortParm) {
        
        guard let collection = notenikIO?.collection else { return }
        
        lnfCol1Title = ""
        
        switch sortParm {
        case .title:
            _ = addTitleColumn(at: 0)
            trimColumns(to: 1)
        case .seqPlusTitle:
            addSeqColumn(at: 0)
            _ = addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .tasksByDate:
            addXColumn(at: 0)
            addDateColumn(at: 1)
            addSeqColumn(at: 2)
            _ = addTitleColumn(at: 3)
            trimColumns(to: 4)
        case .tasksBySeq:
            addXColumn(at: 0)
            addSeqColumn(at: 1)
            addDateColumn(at: 2)
            _ = addTitleColumn(at: 3)
            trimColumns(to: 4)
        case .tagsPlusTitle:
            addTagsColumn(at: 0)
            addStatusDigit(at: 1)
            _ = addTitleColumn(at: 2)
        case .tagsPlusSeq:
            addTagsColumn(at: 0)
            addSeqColumn(at: 1)
            _ = addTitleColumn(at: 2)
        case .author:
            _ = addAuthorColumn(at: 0)
            var columns = 1
            if collection.creatorFieldDef != collection.titleFieldDef {
                _ = addTitleColumn(at: 1)
                columns = 2
            }
            trimColumns(to: columns)
        case .dateAdded:
            addDateAddedColumn(at: 0)
            _ = addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .dateModified:
            addDateModifiedColumn(at: 0)
            _ = addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .datePlusSeq:
            if collection.seqFieldDef == nil {
                addDateColumn(at: 0)
                _ = addTitleColumn(at: 1)
            } else {
                addDateColumn(at: 0)
                addSeqColumn(at: 1)
                _ = addTitleColumn(at: 2)
            }
        case .rankSeqTitle:
            addRankColumn(at: 0)
            addSeqColumn(at: 1)
            _ = addTitleColumn(at: 2)
            trimColumns(to: 3)
        case .klassTitle:
            addKlassColumn(at: 0)
            _ = addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .klassDateTitle:
            addKlassColumn(at: 0)
            addDateColumn(at: 1)
            _ = addTitleColumn(at: 2)
            trimColumns(to: 3)
        case .folderTitle:
            addFolderColumn(at: 0)
            _ = addTitleColumn(at: 1)
            trimColumns(to: 2)
        case .folderDateTitle:
            addFolderColumn(at: 0)
            addDateColumn(at: 1)
            _ = addTitleColumn(at: 2)
            trimColumns(to: 3)
        case .folderSeqTitle:
            addFolderColumn(at: 0)
            addSeqColumn(at: 1)
            _ = addTitleColumn(at: 2)
            trimColumns(to: 3)
        case .lastNameFirst:
            switch collection.lastNameFirstConfig {
            case .author:
                lnfCol1Title = addAuthorColumn(at: 0)
                _ = addTitleColumn(at: 1)
                trimColumns(to: 2)
            case .person, .kindPlusPerson:
                lnfCol1Title = addPersonColumn(at: 0)
                trimColumns(to: 1)
            case .title, .kindPlusTitle:
                lnfCol1Title = addTitleColumn(at: 0)
                trimColumns(to: 1)
            }
        case .custom:
            _ = addTitleColumn(at: 0)
            trimColumns(to: 1)
        }
        tableView.reloadData()
    }
    
    func setSortDescending(_ descending: Bool) {
        tableView.reloadData()
    }
    
    func setDateSort(_ sortBlankDatesLast: Bool) {
        tableView.reloadData()
    }
    
    func addTitleColumn(at desiredIndex: Int) -> String {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Title", strID: "title-column", at: desiredIndex, min: 200, width: 445, max: 1500)
            return "Title"
        }
        let col = collection.columnWidths.getColumn(withTitle: "Title")
        addColumn(title: collection.titleFieldDef.fieldLabel.properForm,
                  strID: "title-column",
                  at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        return collection.titleFieldDef.fieldLabel.properForm
    }
    
    func addRankColumn(at desiredIndex: Int) {
        if notenikIO != nil
            && notenikIO!.collection != nil
            && notenikIO!.collection!.rankFieldDef != nil {
            let col = notenikIO!.collection!.columnWidths.getColumn(withTitle: "Rank")
            addColumn(title: notenikIO!.collection!.rankFieldDef!.fieldLabel.properForm,
                      strID: "rank-column",
                      at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        } else {
            addColumn(title: "Rank", strID: "rank-column",
                      at: desiredIndex, min: 50, width: 80, max: 250)
        }
    }
    
    func addKlassColumn(at desiredIndex: Int) {
        if notenikIO != nil
            && notenikIO!.collection != nil
            && notenikIO!.collection!.klassFieldDef != nil {
            let col = notenikIO!.collection!.columnWidths.getColumn(withTitle: "Klass")
            addColumn(title: notenikIO!.collection!.klassFieldDef!.fieldLabel.properForm,
                      strID: "klass-column",
                      at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        } else {
            addColumn(title: NotenikConstants.klass, strID: "klass-column",
                      at: desiredIndex, min: 60, width: 80, max: 150)
        }
    }
    
    func addFolderColumn(at desiredIndex: Int) {
        if notenikIO != nil
            && notenikIO!.collection != nil
            && notenikIO!.collection!.folderFieldDef != nil {
            let col = notenikIO!.collection!.columnWidths.getColumn(withTitle: "Klass")
            addColumn(title: notenikIO!.collection!.folderFieldDef!.fieldLabel.properForm,
                      strID: "klass-column",
                      at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        } else {
            addColumn(title: NotenikConstants.folder, strID: "klass-column",
                      at: desiredIndex, min: 60, width: 80, max: 150)
        }
    }
    
    func addSeqColumn(at desiredIndex: Int) {
        if notenikIO != nil
            && notenikIO!.collection != nil
            && notenikIO!.collection!.seqFieldDef != nil {
            let col = notenikIO!.collection!.columnWidths.getColumn(withTitle: "Seq")
            addColumn(title: notenikIO!.collection!.seqFieldDef!.fieldLabel.properForm,
                      strID: "seq-column",
                      at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        } else {
            addColumn(title: "Seq", strID: "seq-column", at: desiredIndex, min: 30, width: 80, max: 250)
        }
    }
    
    func addXColumn(at desiredIndex: Int) {
        var col = ColumnWidth(title: "X", min: 12, pref: 20, max: 50)
        if let collection = notenikIO?.collection {
            col = collection.columnWidths.getColumn(withTitle: "X")
        }
        addColumn(title: "X", strID: "x-column", at: desiredIndex, min: col.min, width: col.pref, max: col.max)
    }
    
    func addStatusDigit(at desiredIndex: Int) {
        var col = ColumnWidth(title: "status-digit", min: 20, pref: 30, max: 50)
        if let collection = notenikIO?.collection {
            col = collection.columnWidths.getColumn(withTitle: "status-digit")
        }
        addColumn(title: "Stat", strID: "status-digit-column", at: desiredIndex, min: col.min, width: col.pref, max: col.max)
    }
    
    func addDateColumn(at desiredIndex: Int) {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Date", strID: "date-column", at: desiredIndex, min: 80, width: 120, max: 500)
            return
        }
        let col = collection.columnWidths.getColumn(withTitle: "Date")
        addColumn(title: collection.dateFieldDef.fieldLabel.properForm,
                  strID: "date-column",
                  at: desiredIndex, min: col.min, width: col.pref, max: col.max)
    }
    
    func addAuthorColumn(at desiredIndex: Int) -> String {
        guard let collection = notenikIO?.collection else {
            addColumn(title: NotenikConstants.author, strID: "author-column", at: desiredIndex, min: 100, width: 200, max: 1000)
            return NotenikConstants.author
        }
        let col = collection.columnWidths.getColumn(withTitle: "Author")
        addColumn(title: collection.creatorFieldDef.fieldLabel.properForm,
                  strID: "author-column",
                  at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        return collection.creatorFieldDef.fieldLabel.properForm
    }
    
    func addPersonColumn(at desiredIndex: Int) -> String {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Person Name", strID: "person-column", at: desiredIndex, min: 100, width: 200, max: 1000)
            return "Person Name"
        }
        let col = collection.columnWidths.getColumn(withTitle: "Person Name")
        addColumn(title: collection.personDef!.fieldLabel.properForm,
                  strID: "person-column",
                  at: desiredIndex, min: col.min, width: col.pref, max: col.max)
        return collection.personDef!.fieldLabel.properForm
    }
    
    func addTagsColumn(at desiredIndex: Int) {
        guard let collection = notenikIO?.collection else {
            addColumn(title: "Tags", strID: "tags-column", at: desiredIndex, min: 50, width: 100, max: 1200)
            return
        }
        let col = collection.columnWidths.getColumn(withTitle: "Tags")
        addColumn(title: collection.tagsFieldDef.fieldLabel.properForm,
                  strID: "tags-column",
                  at: desiredIndex, min: col.min, width: col.pref, max: col.max)
    }
    
    func addDateAddedColumn(at desiredIndex: Int) {
        var col = ColumnWidth(title: "Date Added", min: 100, pref: 180, max: 250)
        if let collection = notenikIO?.collection {
            col = collection.columnWidths.getColumn(withTitle: "Date Added")
        }
        addColumn(title: "Date Added", strID: "date-added-column", at: desiredIndex, min: col.min, width: col.pref, max: col.max)
    }
    
    func addDateModifiedColumn(at desiredIndex: Int) {
        var col = ColumnWidth(title: "Date Mod", min: 100, pref: 180, max: 250)
        if let collection = notenikIO?.collection {
            col = collection.columnWidths.getColumn(withTitle: "Date Mod")
        }
        addColumn(title: "Date Mod", strID: "date-mod-column", at: desiredIndex, min: col.min, width: col.pref, max: col.max)
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
    
    /// If the user resized a column, then capture the preferred column width. 
    func tableViewColumnDidResize(_ notification: Notification) {
        if let tableColumn = notification.userInfo?["NSTableColumn"] as? NSTableColumn {
            if let collection = notenikIO?.collection {
                let type = String(tableColumn.identifier.rawValue.dropLast(7))
                let cw = ColumnWidth(title: type, min: 20, pref: 100, max: 1500)
                let min = tableColumn.minWidth
                if min > 10 && min < 1000 {
                    cw.min = Int(min)
                }
                let pref = tableColumn.width
                if pref >= 0 && pref < 5000 {
                    cw.pref = Int(pref)
                }
                let max = tableColumn.maxWidth
                if max > 0 && max < 32000 {
                    cw.max = Int(max)
                }
                collection.columnWidths.add(cw)
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Compliance with CollectionView protocol.
    //
    // -----------------------------------------------------------
    
    var viewID = "notes-list"
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    func focusOn(initViewID: String, 
                 note: NotenikLib.Note?,
                 position: NotenikLib.NotePosition?,
                 io: any NotenikLib.NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        
        guard initViewID != viewID else { return }
        guard position != nil && position!.valid else { return }
        if withUpdates {
            reload()
        }
        programmaticSelection = true
        self.checkForMods = false
        let indexSet = IndexSet(integer: position!.index)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        // if andScroll {
            scrollToSelectedRow()
        // }
        self.checkForMods = true
        programmaticSelection = false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Utilities.
    //
    // -----------------------------------------------------------
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotesListViewController",
                          level: .info,
                          message: msg)
    }
    
}

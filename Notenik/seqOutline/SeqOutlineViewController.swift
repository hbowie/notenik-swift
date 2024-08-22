//
//  SeqOutlineViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 8/6/24.
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class SeqOutlineViewController: NSViewController,
                                NSOutlineViewDataSource,
                                NSOutlineViewDelegate,
                                CollectionView {
    
    let defaults = UserDefaults.standard
    
    @IBOutlet var outlineView: NSOutlineView!
    
    var collectionWindowController: CollectionWindowController?
    
    var notenikIO: NotenikIO?
    
    var focusNote: Note?
    
    var shortcutMenu: NSMenu!
    
    var newChildIndex = -1
    var newWithOptionsIndex = -1
    var seqModIndex = -1
    
    /// Get or Set the Window Controller
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
            if shortcutMenu != nil {
                modShortcutMenuForCollection()
            }
            if outlineView != nil {
                outlineView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        adjustFonts()
        outlineView.dataSource = self
        outlineView.delegate = self
        
        // Setup for drag and drop.
        outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeBookmark as String),
                                             NSPasteboard.PasteboardType(kUTTypeURL as String),
                                             NSPasteboard.PasteboardType(kUTTypeVCard as String),
                                             NSPasteboard.PasteboardType.string])
        
        if focusNote != nil {
            focusOnNote()
        }
        
        // Setup the popup menu for rows in the list.
        shortcutMenu = NSMenu()
        addToShortcutMenu(actionType: .showInFinder)
        addToShortcutMenu(actionType: .launchLink)
        addToShortcutMenu(actionType: .share)
        addToShortcutMenu(actionType: .copyNotenikURL)
        addToShortcutMenu(actionType: .copyTitle)
        addToShortcutMenu(actionType: .copyTimestamp)
        addToShortcutMenu(actionType: .bulkEdit)
 
        shortcutMenu.addItem(NSMenuItem.separator())
        
        addToShortcutMenu(actionType: .duplicate)
        addToShortcutMenu(actionType: .deleteRange)
        
        outlineView.menu = shortcutMenu
        
        if notenikIO != nil {
            modShortcutMenuForCollection()
        }
    }
    
    func reload() {
        adjustFonts()
        outlineView.reloadData()
    }
    
    var monoDigitFont: NSFont?
    var userFont: NSFont?
    var userFontName = ""
    var fontToUse: NSFont?
    
    func adjustFonts() {

        monoDigitFont = NSFont.monospacedDigitSystemFont(ofSize: 13.0,
                                                         weight: NSFont.Weight.regular)
        fontToUse = monoDigitFont
        userFont = nil
        var rowHeight: CGFloat = 17.0
        if let userFontName = defaults.string(forKey: NotenikConstants.listDisplayFont) {
            if !userFontName.isEmpty && !userFontName.lowercased().contains("system font") {
                if let userFontSize = defaults.string(forKey: NotenikConstants.listDisplaySize) {
                    if let doubleValue = Double(userFontSize) {
                        let cgFloat = CGFloat(doubleValue)
                        rowHeight = cgFloat * 1.3
                        userFont = NSFont(name: userFontName, size: cgFloat)
                        fontToUse = userFont
                    }
                }
            }
        }
        if userFont == nil {
            outlineView.rowHeight = CGFloat(17.0)
            outlineView.rowSizeStyle = .custom
        } else {
            outlineView.rowHeight = rowHeight
            outlineView.rowSizeStyle = .custom
        }
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
            addToShortcutMenu(actionType: .modifySeqRange)
        }
        
        if collection.seqFieldDef != nil && collection.levelFieldDef != nil {
            newChildIndex = shortcutMenu.numberOfItems
            addToShortcutMenu(actionType: .newChild)
        }
        
        if (collection.klassFieldDef != nil
               && collection.klassDefs.count > 0)
                || collection.levelFieldDef != nil
                || collection.seqFieldDef != nil {
            newWithOptionsIndex = shortcutMenu.numberOfItems
            addToShortcutMenu(actionType: .newWithOptions)
        }
    }
    
    func addToShortcutMenu(actionType: NoteActionType) {
        let item = NSMenuItem(title: actionType.rawValue,
                              action: #selector(takeShortcutAction(_:)),
                              keyEquivalent: "")
        shortcutMenu.addItem(item)
    }
    
    @IBAction func takeShortcutAction(_ sender: Any) {
        guard let menuItem = sender as? NSMenuItem else { return }
        guard let actionType = NoteActionType(rawValue: menuItem.title) else { return }
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        guard let wc = collectionWindowController else { return }
        let row = outlineView.clickedRow
        guard row >= 0 else { return }
        guard let node = outlineView.item(atRow: row) as? OutlineNode2 else { return }
        guard node.type == .note else { return }
        let clickedNote = node.note!
        
        var selNotes: [Note] = []
        for index in outlineView.selectedRowIndexes {
            guard let node = outlineView.item(atRow: index) as? OutlineNode2 else { continue }
            guard node.type == .note else { continue }
            selNotes.append(node.note!)
        }
        
        switch actionType {
        case .showInFinder:
            let folderPath = io.collection!.lib.getPath(type: .collection)
            let filePath = clickedNote.noteID.getFullPath(note: clickedNote)
            NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: folderPath)
        case .launchLink:
            wc.launchLink(for: clickedNote)
        case .share:
            wc.shareNote(clickedNote)
        case .copyNotenikURL:
            let str = clickedNote.getNotenikLink(preferringTimestamp: false)
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .copyTitle:
            let str = clickedNote.noteID.getBasis()
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .copyTimestamp:
            var str = "No timestamp available!"
            if collection.hasTimestamp {
                str = clickedNote.timestampAsString
            }
            let board = NSPasteboard.general
            board.clearContents()
            board.setString(str, forType: NSPasteboard.PasteboardType.string)
        case .bulkEdit:
            wc.bulkEdit(notes: selNotes)
        case .newWithOptions:
            wc.newWithOptions(currentNote: clickedNote)
        case .duplicate:
            wc.duplicateNote(startingNote: clickedNote)
        case .deleteRange:
            let (lo, hi) = getRangeOfSelectedNotes(io: io)
            guard lo >= 0 && hi >= lo else { return }
            wc.deleteRangeOfNotes(startingRow: lo, endingRow: hi)
        case .newChild:
            wc.newChild(parent: clickedNote)
        case .modifySeqRange:
            guard collection.seqFieldDef != nil 
                    && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) else {
                return
            }
            let (lo, hi) = getRangeOfSelectedNotes(io: io)
            guard lo >= 0 && hi >= lo else { return }
            wc.seqModify(startingRow: lo, endingRow: hi)
        }
    }
    
    func getRangeOfSelectedNotes(io: NotenikIO, withClick: Bool = true) -> (Int, Int) {
        
        guard outlineView.numberOfSelectedRows > 0 else { return (-1, -2) }

        // Get the full range of selected notes.
        let (lowIndex, highIndex) = getRangeOfSelectedRows()
        guard lowIndex >= 0 else { return (-1, -2) }
        // Make sure the user clicked somewhere within this range.
        if withClick && (outlineView.clickedRow > highIndex || outlineView.clickedRow < lowIndex) {
            return (-1, -2)
        }
        
        guard let node1 = outlineView.item(atRow: lowIndex) as? OutlineNode2 else { return  (-1, -2) }
        guard node1.type == .note else { return  (-1, -2) }
        let lowNote = node1.note!
        let lowPosition = io.positionOfNote(lowNote)
        let lo = lowPosition.index
        
        guard let node2 = outlineView.item(atRow: highIndex) as? OutlineNode2 else { return (-1, -2) }
        guard node2.type == .note else { return (-1, -2) }
        let highNote = node2.note!
        let highPosition = io.positionOfNote(highNote)
        let hi = highPosition.index
        
        return (lo, hi)
    }
    
    /// Get a possible range of selected rows from the table view.
    /// - Returns: The first (lowest) row selected, and the highest row selected,
    /// or a pair of negative values is no valid selection.
    func getRangeOfSelectedRows() -> (Int, Int) {

        let selectedRow = outlineView.selectedRow
        if selectedRow < 0 { return (-1, -1) }
        
        var lowIndex = selectedRow
        var highIndex = selectedRow
        
        var rowToTest = selectedRow - 1
        var stillSelected = true
        while rowToTest >= 0 && stillSelected {
            if outlineView.isRowSelected(rowToTest) {
                lowIndex = rowToTest
                rowToTest -= 1
            } else {
                stillSelected = false
            }
        }
        
        rowToTest = outlineView.selectedRow + 1
        stillSelected = true
        while rowToTest < outlineView.numberOfRows && stillSelected {
            if outlineView.isRowSelected(rowToTest) {
                highIndex = rowToTest
                rowToTest += 1
            } else {
                stillSelected = false
            }
        }
        
        return (lowIndex, highIndex)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement NSOutlineViewDataSource
    //
    // -----------------------------------------------------------
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? OutlineNode2 {
            return node.children.count
        }
        guard notenikIO != nil else { return 0 }
        guard notenikIO!.getOutlineNodeRoot() != nil else { return 0 }
        return notenikIO!.getOutlineNodeRoot()!.children.count
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? OutlineNode2 {
            return node.children[index]
        }
        return notenikIO!.getOutlineNodeRoot()!.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? OutlineNode2 {
            return node.children.count > 0
        }
        return notenikIO!.getOutlineNodeRoot()!.children.count > 0
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement Drag and Drop logic.
    //
    // -----------------------------------------------------------
    
    /// Write a selected item to the pasteboard.
    func outlineView(_ outlineView: NSOutlineView,
                     pasteboardWriterForItem item: Any)
                        -> NSPasteboardWriting? {
        if let node = item as? OutlineNode2 {
            if let selectedNote = node.note {
                let maker = NoteLineMaker()
                let _ = maker.putNote(selectedNote, includeAttachments: true)
                var str = ""
                if let writer = maker.writer as? BigStringWriter {
                    str = writer.bigString
                }
                return str as NSString
            }
        }
        return nil
    }
    
    /// Validate a proposed drop operation.
    func outlineView(_ outlineView: NSOutlineView,
                     validateDrop info: NSDraggingInfo,
                     proposedItem item: Any?,
                     proposedChildIndex index: Int)
                    -> NSDragOperation {
        return .copy
    }
    
    /// Process one or more dropped items.
    func outlineView(_ outlineView: NSOutlineView,
                     acceptDrop info: NSDraggingInfo,
                     item: Any?,
                     childIndex index: Int) -> Bool {
        
        guard let wc = collectionWindowController else { return false }
        guard let io = notenikIO else { return false }
        guard let parentNode = item as? OutlineNode2 else { return false }
        guard let parentNote = parentNode.note else { return false }
        
        var noteAbove: Note?
        if parentNode.children.count == 0 || index == 0 {
            noteAbove = parentNote
        } else if index < 0 || index >= parentNode.children.count {
            noteAbove = parentNode.children[parentNode.children.count - 1].note
        } else {
            noteAbove = parentNode.children[index - 1].note
        }
        guard noteAbove != nil else { return false }
        let abovePosition = io.positionOfNote(noteAbove!)
        guard abovePosition.valid else { return false }
        let row = abovePosition.index + 1
        
        let pasteboard = info.draggingPasteboard
        
        let items = pasteboard.pasteboardItems
                        
        var notesPasted = 0
        
        if items != nil && items!.count > 0 {
            notesPasted = wc.pasteItems(items!,
                                        row: row,
                                        dropOperation: .above)
        }
        
        guard notesPasted == 0 else { return true }
        
        let filePromises = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil)
        if filePromises != nil {
            collectionWindowController!.pastePromises(filePromises!)
            return true
        }
        
        return true
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement NSOutlineViewDelegate
    //
    // -----------------------------------------------------------
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var cellView: NSTableCellView?
        
        if let node = item as? OutlineNode2 {
            let cellID = NSUserInterfaceItemIdentifier("seqTableCell")
            cellView = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = cellView?.textField {
                if fontToUse != nil {
                    textField.font = fontToUse!
                }
                switch node.type {
                case .root:
                    textField.stringValue = notenikIO!.collection!.path
                case .note:
                    if let note = node.note {
                        textField.stringValue = note.getTitle(withSeq: true, sep: " - ")
                    } else {
                        textField.stringValue = "???"
                    }
                }
                textField.sizeToFit()
            }
        }
        return cellView
    }
    
    /// Show the user the details for the row s/he selected
    func outlineViewSelectionDidChange(_ notification: Notification) {
        
        guard let outlineView = notification.object as? NSOutlineView else { return }
        guard collectionWindowController != nil else { return }
        let selectedIndex = outlineView.selectedRow
        guard let node = outlineView.item(atRow: selectedIndex) as? OutlineNode2 else { return }
        switch node.type {
        case .note:
            focusNote = node.note!
            _ = coordinator!.focusOn(initViewID: viewID,
                                     note: node.note!,
                                     position: nil,
                                     row: -1,
                                     searchPhrase: nil)
        case .root:
            break
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        
        guard collectionWindowController != nil else { return }
        
        let item = sender.item(atRow: sender.clickedRow)
        guard let node = item as? OutlineNode2 else { return }
        
        if node.type == .note {
            let clickedNote = node.note
            if clickedNote != nil {
                collectionWindowController!.launchLink(for: clickedNote!)
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement CollectionView
    //
    // -----------------------------------------------------------
    
    public static let staticViewID = "seq-outline"
    var viewID = staticViewID
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    /// Select the specified Note, by specifying either the Note itself or its position in the list.
    /// - Parameters:
    ///   - note: The note to be selected.
    ///   - position: The position of the selection.
    ///   - searchPhrase: Any search phrase currently in effect.
    func focusOn(initViewID: String,
                 note: Note?,
                 position: NotePosition?,
                 io: NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        
        guard viewID != initViewID else { return }
        guard note != nil else { return }
        focusNote = note
        guard outlineView != nil else {
            return
        }
        if withUpdates {
            reload()
        }
        focusOnNote()
    }
    
    func focusOnNote() {
        guard notenikIO != nil else {
            return
        }
        let iterator = notenikIO!.makeOutlineNodeIterator()
        var nextNode = iterator.next()
        var found = false
        while nextNode != nil && !found {
            if nextNode!.type == .note {
                if nextNode!.note!.id == focusNote!.id {
                    found = true
                }
            }
            if !found {
                nextNode = iterator.next()
            }
        }
        if found {
            
            // Expand parents so child will be visible
            var parentStack: [OutlineNode2] = []
            var stackComplete = false
            var childNode: OutlineNode2 = nextNode!
            while !stackComplete {
                if childNode.hasParent {
                    parentStack.insert(childNode.parent!, at: 0)
                    childNode = parentStack[0]
                } else {
                    stackComplete = true
                }
            }
            for parent in parentStack {
                outlineView.expandItem(parent)
            }
            
            // Select the row containing the note.
            let row = outlineView.row(forItem: nextNode)
            if row >= 0 {
                let iSet = IndexSet(integer: row)
                outlineView.selectRowIndexes(iSet, byExtendingSelection: false)
            }
        } else {
            print("  - Note ID of \(focusNote!.id) could not be found")
        }
        return
    }
    
}

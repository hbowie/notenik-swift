//
//  NoteTagsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019-2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class NoteTagsViewController: NSViewController,
                              NSOutlineViewDataSource,
                              NSOutlineViewDelegate,
                              CollectionView {
    
    let defaults = UserDefaults.standard
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?

    @IBOutlet var outlineView: NSOutlineView!
    
    var shortcutMenu: NSMenu!
    
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
            outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustFonts()
        outlineView.dataSource = self
        
        // Setup the popup menu for rows in the list.
        shortcutMenu = NSMenu()
        shortcutMenu.addItem(NSMenuItem(title: "Launch Link", action: #selector(launchLinkForItem(_:)), keyEquivalent: ""))
        shortcutMenu.addItem(NSMenuItem(title: "Bulk Edit...", action: #selector(bulkEdit(_:)), keyEquivalent: ""))
        outlineView.menu = shortcutMenu
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
    
    /// Expand the given tag so that its children are visible
    /// - Parameter forTag: The tag to be expanded.
    public func expand(forTag: String) {
        let lowerTagTarget = forTag.lowercased()
        let tags = lowerTagTarget.split(separator: ".")
        guard tags.count > 0 else { return }
        var lookingFor = 0
        let itemCount = outlineView.numberOfRows
        var i = -1
        while (i + 1) < itemCount {
            i += 1
            guard let item = outlineView.item(atRow: i) else { continue }
            guard let node = item as? TagsNode else { continue }
            guard node.children.count > 0 else { continue }
            guard node.type == .tag else { continue }
            guard let tag = node.tag else { continue }
            if lookingFor < tags.count && tag.lowercased() == tags[lookingFor] {
                outlineView.expandItem(item, expandChildren: true)
                lookingFor += 1
                if lookingFor >= tags.count {
                    outlineView.scrollRowToVisible(i+1)
                    continue
                } else {
                    continue
                }
            } else if outlineView.isItemExpanded(item) {
                outlineView.collapseItem(item, collapseChildren: true)
            }
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        
        guard collectionWindowController != nil else { return }
        
        let item = sender.item(atRow: sender.clickedRow)
        guard let node = item as? TagsNode else { return }
        
        if node.type == .tag {
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        } else if node.type == .note {
            let clickedNote = node.note
            if clickedNote != nil {
                collectionWindowController!.launchLink(for: clickedNote!)
            }
        }
    }
    
    /// Launch a Note's Link
    @IBAction func launchLink(_ sender: Any) {
        for index in outlineView.selectedRowIndexes {
            launchLinkForRow(index)
        }
    }
    
    /// Respond to a contextual menu selection to launch a link for the clicked Note.
    @objc private func launchLinkForItem(_ sender: AnyObject) {
       
        guard outlineView.clickedRow >= 0 else { return }
        
        var clickedWithinSelected = false
        for index in outlineView.selectedRowIndexes {
            if outlineView.clickedRow == index {
                clickedWithinSelected = true
                break
            }
        }
        
        if clickedWithinSelected {
            for index in outlineView.selectedRowIndexes {
                launchLinkForRow(index)
            }
        } else {
            launchLinkForRow(outlineView.clickedRow)
        }

    }
    
    func launchLinkForRow(_ row: Int) {
        
        guard row >= 0 else { return }
        guard let wc = collectionWindowController else { return }
        
        let item = outlineView.item(atRow: row)
        guard let node = item as? TagsNode else { return }
        
        if node.type == .note {
            let clickedNote = node.note
            if clickedNote != nil {
                wc.launchLink(for: clickedNote!)
            }
        }
    }
    
    /// Bulk edit a set of selected Notes.
    @IBAction func bulkEdit(_ sender: Any) {
        guard let wc = collectionWindowController else { return }
        // guard let io = notenikIO else { return }
        var selNotes: [Note] = []
        
        var clickedWithinSelected = false
        for index in outlineView.selectedRowIndexes {
            if outlineView.clickedRow == index {
                clickedWithinSelected = true
                break
            }
        }
        
        if clickedWithinSelected {
            for index in outlineView.selectedRowIndexes {
                selectNoteAtRow(index, notes: &selNotes)
            }
        } else {
            selectNoteAtRow(outlineView.clickedRow, notes: &selNotes)
        }
        
        wc.bulkEdit(notes: selNotes)
    }
    
    func selectNoteAtRow(_ row: Int, notes: inout [Note]) {
        
        guard row >= 0 else { return }
        
        let item = outlineView.item(atRow: row)
        guard let node = item as? TagsNode else { return }
        
        if node.type == .note {
            let clickedNote = node.note
            if clickedNote != nil {
                notes.append(clickedNote!)
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement NSOutlineViewDataSource
    //
    // -----------------------------------------------------------
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? TagsNode {
            return node.children.count
        }
        guard notenikIO != nil else { return 0 }
        guard notenikIO!.getTagsNodeRoot() != nil else { return 0 }
        return notenikIO!.getTagsNodeRoot()!.children.count
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? TagsNode {
            return node.children[index]
        }
        
        return notenikIO!.getTagsNodeRoot()!.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? TagsNode {
            return node.children.count > 0
        }
        
        return notenikIO!.getTagsNodeRoot()!.children.count > 0
    }
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let node = item as? TagsNode {
            let cellID = NSUserInterfaceItemIdentifier("tagsCell")
            view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.font = fontToUse!
                switch node.type {
                case .root:
                    textField.stringValue = notenikIO!.collection!.path
                case .tag:
                    textField.stringValue = node.tag!.forDisplay
                case .note:
                    if let note = node.note {
                        let sortParm = note.collection.sortParm
                        if sortParm == .seqPlusTitle
                            || sortParm == .tasksBySeq
                            || sortParm == .datePlusSeq
                            || sortParm == .tagsPlusSeq {
                            textField.stringValue = node.note!.getTitle(withSeq: true, sep: " - ")
                        } else {
                            textField.stringValue = node.note!.title.value
                        }
                    } else {
                        textField.stringValue = "???"
                    }
                }
                textField.sizeToFit()
            }
        }
        return view
    }
    
    /// Show the user the details for the row s/he selected
    func outlineViewSelectionDidChange(_ notification: Notification) {

        guard let outlineView = notification.object as? NSOutlineView else { return }
        guard collectionWindowController != nil else { return }
        
        // let (outcome, _) = collectionWindowController!.modIfChanged()
        // guard outcome != modIfChangedOutcome.tryAgain else { return }
        // collectionWindowController!.applyCheckBoxUpdates()
        
        let selectedIndex = outlineView.selectedRow
        guard let node = outlineView.item(atRow: selectedIndex) as? TagsNode else { return }
        switch node.type {
        case .note:
            _ = coordinator!.focusOn(initViewID: viewID,
                                     note: node.note!,
                                     position: nil, row: -1, searchPhrase: nil)
            // collectionWindowController!.select(note: node.note!, position: nil, source: .tree)
        case .tag:
            var nextChildNode: TagsNode = node
            var childrenExhausted = false
            while nextChildNode.type != .note && !childrenExhausted {
                if nextChildNode.children.count == 0 {
                    childrenExhausted = true
                } else {
                    nextChildNode = nextChildNode.children[0]
                }
            }
            if nextChildNode.type == .note {
                _ = coordinator!.focusOn(initViewID: viewID,
                                         note: nextChildNode.note!,
                                         position: nil, row: -1, searchPhrase: nil)
                // collectionWindowController!.select(note: nextChildNode.note!, position: nil, source: .tree)
            }
        case .root:
            break
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Implement ControlView protocol.
    //
    // -----------------------------------------------------------
    
    var viewID: String = "tags-outline"
    
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
        
        guard viewID != initViewID else { return }
        guard note != nil else { return }
        guard outlineView != nil else {
            print("  - tags outline view is nil!")
            return
        }

        guard notenikIO != nil else {
            return
        }
        
        if withUpdates {
            reload()
        }
        let iterator = notenikIO!.makeTagsNodeIterator()
        var nextNode = iterator.next()
        var found = false
        while nextNode != nil && !found {
            if nextNode!.type == .note {
                if nextNode!.note!.id == note!.id {
                    found = true
                }
            }
            if !found {
                nextNode = iterator.next()
            }
        }
        if found {
            var parentNode: TagsNode?
            if nextNode!.hasParent {
                parentNode = nextNode!.parent
            } else if let parent = outlineView.parent(forItem: nextNode) as? TagsNode {
                parentNode = parent
            }
            if parentNode != nil {
                outlineView.expandItem(parentNode)
            } else {
                print("  - could not find a parent!")
            }
            let row = outlineView.row(forItem: nextNode)
            if row >= 0 {
                let iSet = IndexSet(integer: row)
                outlineView.selectRowIndexes(iSet, byExtendingSelection: false)
            }
        } else {
            print("  - Note ID of \(note!.id) could not be found")
        }
        return
    }
    
}

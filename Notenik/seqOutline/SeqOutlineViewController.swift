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

class SeqOutlineViewController: NSViewController,
                                NSOutlineViewDataSource,
                                NSOutlineViewDelegate,
                                CollectionView {
    
    @IBOutlet var outlineView: NSOutlineView!
    
    var collectionWindowController: CollectionWindowController?
    
    var notenikIO: NotenikIO?
    
    var focusNote: Note?
    
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
            if outlineView != nil {
                outlineView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        outlineView.delegate = self
        if focusNote != nil {
            focusOnNote()
        }
    }
    
    func reload() {
        outlineView.reloadData()
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
    // MARK: Implement NSOutlineViewDelegate
    //
    // -----------------------------------------------------------
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var view: NSTableCellView?
        
        if let node = item as? OutlineNode2 {
            let cellID = NSUserInterfaceItemIdentifier("seqTableCell")
            view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = view?.textField {
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
        return view
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

//
//  NoteTagsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class NoteTagsViewController: NSViewController,
                              NSOutlineViewDataSource,
                              NSOutlineViewDelegate {
    
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
        outlineView.dataSource = self
        
        // Setup the popup menu for rows in the list.
        shortcutMenu = NSMenu()
        shortcutMenu.addItem(NSMenuItem(title: "Launch Link", action: #selector(launchLinkForItem(_:)), keyEquivalent: ""))
        outlineView.menu = shortcutMenu
    }
    
    func reload() {
        outlineView.reloadData()
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
        
        let (outcome, _) = collectionWindowController!.modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        let selectedIndex = outlineView.selectedRow
        guard let node = outlineView.item(atRow: selectedIndex) as? TagsNode else { return }
        switch node.type {
        case .note:
            collectionWindowController!.select(note: node.note!, position: nil, source: .tree)
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
                collectionWindowController!.select(note: nextChildNode.note!, position: nil, source: .tree)
            }
        case .root:
            break
        }
    }
    
}

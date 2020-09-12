//
//  NoteTagsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
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
    
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? TagsNode {
            return node.children.count
        }
        if notenikIO == nil {
            return 0
        } else {
            return notenikIO!.getTagsNodeRoot()!.children.count
        }
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
                    textField.stringValue = node.tag!
                case .note:
                    textField.stringValue = node.note!.title.value
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
        
        let outcome = collectionWindowController!.modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        let selectedIndex = outlineView.selectedRow
        if let node = outlineView.item(atRow: selectedIndex) as? TagsNode {
            if node.type == TagsNodeType.note {
                collectionWindowController!.select(note: node.note!, position: nil, source: .tree)
            }
        }
    }
    
}

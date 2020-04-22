//
//  PickerViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/20/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CollectorViewController: NSViewController,
        NSOutlineViewDataSource,
        NSOutlineViewDelegate {
    
    var collectorWindowController: CollectorWindowController?

    @IBOutlet var outlineView: NSOutlineView!
    
    var tree: CollectorTree?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        outlineView.delegate = self
    }
    
    func reload() {
        outlineView.reloadData()
    }
    
    /// Get or Set the Window Controller
    var window: CollectorWindowController? {
        get {
            return collectorWindowController
        }
        set {
            collectorWindowController = newValue
        }
    }
    
    func passCollectorRequesterInfo(tree: CollectorTree) {
        self.tree = tree
        outlineView.reloadData()
    }
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? CollectorNode {
            return node.children.count
        }
        if tree == nil {
            return 0
        } else {
            return tree!.root.children.count
        }
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? CollectorNode {
            return node.getChild(at: index) as Any
        }
        
        return tree!.root.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? CollectorNode {
            return node.children.count > 0
        }
        
        return tree!.root.children.count > 0
    }
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?,
                     item: Any) -> NSView? {
        
        var view: NSTableCellView?
        
        if let node = item as? CollectorNode {
            let cellID = NSUserInterfaceItemIdentifier("collectorCellView")
            view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = view?.textField {
                switch node.type {
                case .root:
                    textField.stringValue = "root"
                case .folder:
                    if node.folder == "" {
                        textField.stringValue = node.base
                    } else {
                        textField.stringValue = node.folder
                    }
                case .collection:
                    textField.stringValue = node.folder
                }
                textField.sizeToFit()
            }
        }
        return view
    }
    

    @IBAction func ExpandPushed(_ sender: Any) {
    }
    
    @IBAction func collapsePushed(_ sender: Any) {
    }
    
    @IBAction func openPushed(_ sender: Any) {
    }
    
    @IBAction func newPushed(_ sender: Any) {
    }
}

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

import NotenikUtils

class CollectorViewController: NSViewController,
        NSOutlineViewDataSource,
        NSOutlineViewDelegate {
    
    var collectorWindowController: CollectorWindowController?

    @IBOutlet var outlineView: NSOutlineView!
    
    @IBOutlet var newFolderTextField: NSTextField!
    
    var tree: CollectorTree?
    
    var juggler: CollectionJuggler?
    
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
    
    func passCollectorRequesterInfo(juggler: CollectionJuggler, tree: CollectorTree) {
        self.juggler = juggler
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
                        textField.stringValue = node.base.name
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
        guard tree != nil else { return }
        for node in tree! {
            if node.hasChildren {
                outlineView.expandItem(node)
            }
        }
    }
    
    @IBAction func collapsePushed(_ sender: Any) {
        guard tree != nil else { return }
        for node in tree! {
            if node.hasChildren {
                outlineView.collapseItem(node)
            }
        }
    }
    
    @IBAction func openPushed(_ sender: Any) {
        guard juggler != nil else { return }
        let selRow = outlineView.selectedRow
        let selItem = outlineView.item(atRow: selRow) as? CollectorNode
        guard selItem != nil else { return }
        let selURL = selItem?.url
        guard selURL != nil else { return }
        var urls: [URL] = []
        urls.append(selURL!)
        _ = juggler!.open(urls: urls)
    }
    
    @IBAction func outlineDoubleClicked(_ sender: NSOutlineView) {
        guard juggler != nil else { return }
        let selItem = sender.item(atRow: sender.clickedRow) as? CollectorNode
        guard selItem != nil else { return }
        let selURL = selItem?.url
        guard selURL != nil else { return }
        var urls: [URL] = []
        urls.append(selURL!)
        _ = juggler!.open(urls: urls)
    }
    
    
    @IBAction func newPushed(_ sender: Any) {
        print("New Button Pushed")
        guard juggler != nil else { return }
        guard tree != nil else { return }
        let selRow = outlineView.selectedRow
        let selItem = outlineView.item(atRow: selRow) as? CollectorNode
        guard selItem != nil else { return }
        let base = selItem!.base
        let newFolder = newFolderTextField.stringValue
        guard newFolder.count > 0 else {
            communicateError("Please enter the desired name of the new Collection", alert: true)
            return
        }
        print("Base URL = \(base.url.path)")
        print("New folder is \(newFolder)")
        let newURL = base.url.appendingPathComponent(newFolder, isDirectory: true)
        print("New URL = \(newURL.absoluteString)")
        var ok = juggler!.newFolder(folderURL: newURL)
        guard ok else {
            communicateError("New Collection Could Not Be Created with the given Name", alert: true)
            return
        }

        ok = juggler!.newCollection(fileURL: newURL)
        guard ok else {
            communicateError("New Collection could not be successfully created", alert: true)
            return
        }
        tree!.add(newURL)
        print("New URL added to board")
        reload()
        print("Reload of data complete")
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectorViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
}

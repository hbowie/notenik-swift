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
import NotenikLib

class CollectorViewController:
        NSViewController,
        NSOutlineViewDataSource,
        NSOutlineViewDelegate,
        KnownFoldersViewer {
    
    var collectorWindowController: CollectorWindowController?

    @IBOutlet var outlineView: NSOutlineView!
    
    @IBOutlet var newCollectionName: NSTextField!
    
    var knownFolders: KnownFolders?
    
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
    
    func passCollectorRequesterInfo(juggler: CollectionJuggler, tree: KnownFolders) {
        self.juggler = juggler
        self.knownFolders = tree
        tree.registerViewer(self)
        outlineView.reloadData()
    }
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? KnownFolderNode {
            return node.children.count
        }
        if knownFolders == nil {
            return 0
        } else {
            return knownFolders!.root.children.count
        }
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? KnownFolderNode {
            return node.getChild(at: index) as Any
        }
        
        return knownFolders!.root.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let node = item as? KnownFolderNode {
            return node.children.count > 0
        }
        
        return knownFolders!.root.children.count > 0
    }
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView,
                     viewFor tableColumn: NSTableColumn?,
                     item: Any) -> NSView? {
        
        var view: NSTableCellView?
        
        if let node = item as? KnownFolderNode {
            let cellID = NSUserInterfaceItemIdentifier("collectorCellView")
            view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if view != nil {
                switch node.type {
                case .root:
                    view!.toolTip = "Root of Outline View"
                case .folder, .collection:
                    view!.toolTip = node.url.path
                }
            }
            
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
                
                if node.known == nil {
                    // print("No Known Folder for node: \(node)")
                }
                if let known = node.known {
                    if known.isCollection {
                        let fontSize = NSFont.systemFontSize
                        textField.font = NSFont.boldSystemFont(ofSize: fontSize)
                    } else if known.fromBookmark {
                        let fontSize = NSFont.systemFontSize
                        let fontMgr = NSFontManager.shared
                        let oldFont = NSFont.systemFont(ofSize: fontSize)
                        let italics = fontMgr.convert(oldFont, toHaveTrait: .italicFontMask)
                        textField.font = italics
                    }
                }
                
                textField.sizeToFit()
            }
        }
        return view
    }

    @IBAction func ExpandPushed(_ sender: Any) {
        guard knownFolders != nil else { return }
        for node in knownFolders! {
            if node.hasChildren {
                outlineView.expandItem(node)
            }
        }
    }
    
    @IBAction func collapsePushed(_ sender: Any) {
        guard knownFolders != nil else { return }
        for node in knownFolders! {
            if node.hasChildren {
                outlineView.collapseItem(node)
            }
        }
    }
    
    @IBAction func openPushed(_ sender: Any) {
        let selRow = outlineView.selectedRow
        guard let selItem = outlineView.item(atRow: selRow) as? KnownFolderNode else { return }
        openURL(knownFolderNode: selItem)
    }
    
    @IBAction func outlineDoubleClicked(_ sender: NSOutlineView) {
        guard let selItem = sender.item(atRow: sender.clickedRow) as? KnownFolderNode else { return }
        openURL(knownFolderNode: selItem)
    }
    
    func openURL(knownFolderNode: KnownFolderNode?) {
        guard juggler != nil else { return }
        guard let known = knownFolderNode else { return }
        let knownURL = known.url
        var ok = true
        if let folder = known.known {
            if folder.fromBookmark {
                ok = knownURL.startAccessingSecurityScopedResource()
                if ok {
                    folder.inUse = true
                } else {
                    communicateError("Notenik could not gain access to the folder -- you will need to re-open it.",
                                     alert: true)
                }
            }
        }
        if ok {
            var urls: [URL] = []
            urls.append(knownURL)
            _ = juggler!.open(urls: urls)
        }
    }
    
    @IBAction func parentPushed(_ sender: Any) {
        guard juggler != nil else { return }
        let selRow = outlineView.selectedRow
        guard let known = outlineView.item(atRow: selRow) as? KnownFolderNode else { return }
        let knownURL = known.url
        var ok = true
        if let folder = known.known {
            if folder.fromBookmark {
                ok = knownURL.startAccessingSecurityScopedResource()
                if ok {
                    folder.inUse = true
                } else {
                    communicateError("Notenik could not gain access to the folder -- you will need to re-open it.",
                                     alert: true)
                }
            }
        }
        if ok {
            juggler!.openParentRealm(parentURL: knownURL)
        }
    }
    
    @IBAction func newPushed(_ sender: Any) {
        guard juggler != nil else { return }
        guard knownFolders != nil else { return }
        let folderName = newCollectionName.stringValue
        guard folderName.count > 0 else {
            communicateError("Please specify a folder name for the new Collection", alert: true)
            return
        }
        let newURL = knownFolders!.createNewCloudFolder(folderName: folderName)
        guard newURL != nil else {
            communicateError("New Collection Folder could not be created: see Log for possible details", alert: true)
            return
        }
        let ok = juggler!.newCollection(fileURL: newURL!)
        if !ok {
            communicateError("New Collection could not be created: see Log for possible details", alert: true)
        }
    }
    
    @IBAction func removePushed(_ sender: Any) {
        guard knownFolders != nil else { return }
        let selRow = outlineView.selectedRow
        let selItem = outlineView.item(atRow: selRow) as? KnownFolderNode
        guard selItem != nil else { return }
        knownFolders!.remove(selItem!)
        reload()
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

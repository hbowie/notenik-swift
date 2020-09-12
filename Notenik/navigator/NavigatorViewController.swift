//
//  NavigatorViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 9/10/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class NavigatorViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet var outlineView: NSOutlineView!
    
    @IBOutlet var newICloudFolderName: NSTextField!
    
    var window: NavigatorWindowController!
    
    var juggler: CollectionJuggler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
    }
    
    func reload() {
        outlineView.reloadData()
    }
    
    /// How many children does this node have?
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        // If we have a good node, then return the number of its children.
        if let node = item as? NotenikFolderNode {
            return node.countChildren
        }
        
        // If the passed item was nil, then we must return the number of children
        // for the root node.
        return NotenikFolderList.shared.root.countChildren
    }
    
    /// Return the child of a node at the given index position.
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? NotenikFolderNode {
            return node.children[index]
        }
        return NotenikFolderList.shared.root.children[index]
    }
    
    /// Is this node expandable?
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
      if let node = item as? NotenikFolderNode {
        return node.type != .folder
      }
        
      return false
    }
    
    /// Return a View for this Node
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        var view: NSTableCellView?
        
        if let node = item as? NotenikFolderNode {
            let cellID = NSUserInterfaceItemIdentifier("FolderCell")
            view = outlineView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView
            if let textField = view?.textField {
                switch node.type {
                case .root:
                    textField.stringValue = "root"
                case .group:
                    textField.stringValue = node.desc
                case .folder:
                    textField.stringValue = node.desc
                    if node.folder != nil {
                        textField.toolTip = node.folder!.path
                    }
                }
                textField.sizeToFit()
            }
        }
        return view
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        guard juggler != nil else { return }
        let item = sender.item(atRow: sender.clickedRow)
        guard let node = item as? NotenikFolderNode else { return }
        
        if node.type == .group {
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        } else if node.type == .folder {
            if node.desc == NotenikFolderList.helpFolderDesc {
                juggler!.openHelpNotes()
                closeWindow()
            } else {
                let clickedFolder = node.folder
                if clickedFolder != nil {
                    _ = juggler!.open(urls: [clickedFolder!.url])
                }
            }
        }
    }
    
    /// Close the Navigator Window.
    func closeWindow() {
        guard window != nil else { return }
        window!.close()
    }
    
    /// Open one or more selected items.
    @IBAction func openButton(_ sender: Any) {
        guard juggler != nil else { return }
        for index in 0..<outlineView.numberOfRows {
            guard outlineView.isRowSelected(index) else { continue }
            guard let node = outlineView.item(atRow: index) as? NotenikFolderNode else {
                continue
            }
            guard node.type == .folder else { continue }
            if node.desc == NotenikFolderList.helpFolderDesc {
                juggler!.openHelpNotes()
            } else {
                let clickedFolder = node.folder
                if clickedFolder != nil {
                    _ = juggler!.open(urls: [clickedFolder!.url])
                }
            }
        }
    }
    
    /// Open a folder not visible in the list. 
    @IBAction func openOther(_ sender: Any) {
        guard juggler != nil else { return }
        let success = juggler!.openFolder()
        if success {
            closeWindow()
        }
    }
    
    /// Let the user select a folder to open as a parent realm.
    @IBAction func openParentRealm(_ sender: Any) {
        guard juggler != nil else { return }
        let success = juggler!.openParentRealm()
        if success {
            closeWindow()
        }
    }
    
    
    @IBAction func newCollection(_ sender: Any) {
        guard juggler != nil else { return }
        let folderName = StringUtils.trim(newICloudFolderName.stringValue)
        if folderName.count == 0 {
            juggler!.userRequestsNewCollection()
        } else {
            let url = NotenikFolderList.shared.createNewFolderWithinICloudContainer(folderName: folderName)
            if url != nil {
                juggler!.proceedWithSelectedURL(requestType: .new, fileURL: url!)
            }
        }
    }
    
    /// Delete one or more Collections selected in the outline. 
    @IBAction func deleteCollection(_ sender: Any) {
        guard juggler != nil else { return }
        for index in 0..<outlineView.numberOfRows {
            guard outlineView.isRowSelected(index) else { continue }
            guard let node = outlineView.item(atRow: index) as? NotenikFolderNode else {
                continue
            }
            guard node.type == .folder else { continue }
            if node.desc == NotenikFolderList.helpFolderDesc { continue }
            let selFolder = node.folder
            if selFolder != nil {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Really delete the folder named '\(node.desc)'?"
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Cancel")
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    do {
                        try FileManager.default.removeItem(at: selFolder!.url)
                        _ = NotenikFolderList.shared.remove(folder: selFolder!)
                        logInfo(msg: "Deleted Notenik folder located at: '\(selFolder!.path)'")
                    } catch {
                        communicateError("Error encountered while trying to remove folder at '\(selFolder!.path)'", alert: true)
                    }
                }
            }
        }
        reload()
    }
    
    /// Respond to user request to quit the app.
    @IBAction func quit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    /// Log an info message.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NavigatorViewController",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NavigatorViewController",
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

//
//  NavigatorViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 9/10/20.
//  Copyright © 2020 - 2023 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class NavigatorViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSComboBoxDataSource {

    @IBOutlet var comboPicker: NSComboBox!
    
    @IBOutlet var outlineView: NSOutlineView!
    
    @IBOutlet var newICloudFolderName: NSTextField!
    
    var window: NavigatorWindowController!
    
    var juggler: CollectionJuggler?
    
    var folders: [NavigatorFolder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        loadFolders()
        comboPicker.usesDataSource = true
        comboPicker.dataSource = self
    }
    
    func reload() {
        outlineView.reloadData()
        loadFolders()
        comboPicker.reloadData()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Load the array of folders, with suitable names.
    //
    // -----------------------------------------------------------
    
    func loadFolders() {
        folders = []
        for folder in NotenikFolderList.shared {
            add(link: folder)
        }
        folders.sort()
    }
    
    /// Add a new folder, ensuring it has a distinct name.
    func add(link: NotenikLink) {
        let folderName = link.folder.lowercased()
        let briefDesc = link.briefDesc.lowercased()
        var handleSource = 1
        if !briefDesc.isEmpty && briefDesc.count < 21 && !briefDesc.contains(AppPrefs.shared.idFolderSep) {
            handleSource = 2
        }
        if handleSource == 1 && !briefDesc.isEmpty {
            for folder in folders {
                if folderName == folder.folder {
                    handleSource = 2
                    break
                }
            }
        }
        var handle = folderName
        if handleSource == 2 {
            handle = briefDesc
        }
        let anotherFolder = NavigatorFolder(link: link, handle: handle)
        folders.append(anotherFolder)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Functions providing data source for the Combo Box.
    //
    // -----------------------------------------------------------
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
      return folders.count
    }
        
    /// Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
      return folders[index]
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        let lower = string.lowercased()
        var i = 0
        // var j = -1
        while i < folders.count {
            if folders[i].folder.hasPrefix(lower) {
                return folders[i].folder
            }
            // if folders[i].folder.contains(lower) && j < 0 {
            //     j = i
            // }
            i += 1
        }
        // if j >= 0 {
        //     return folders[j].folder
        // }
        return nil
    }
    
    /// Returns the index of the combo box matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return indexForKey(string)
    }

    
    @IBAction func comboSelection(_ sender: NSComboBox) {
        let str = sender.stringValue
        let i = indexForKey(str)
        guard i != NSNotFound else { return }
        guard let link = folders[i].link else { return }
        open(link: link)
    }
    
    
    /// Return the index of the folder with the passed name.
    /// - Parameter str: The name of the folder.
    /// - Returns: The index of the matching entry, or NSNotFound if nothing matches.
    func indexForKey(_ str: String) -> Int {
        let lower = str.lowercased()
        var i = 0
        while i < folders.count {
            if folders[i].folder == lower {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Functions supporting the Outline View.
    //
    // -----------------------------------------------------------
    
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
            let clickedFolder = node.folder
            if clickedFolder != nil {
                _ = juggler!.open(link: clickedFolder!)
            }
        }
    }
    
    func open(link: NotenikLink) {
        let wc = juggler!.open(link: link)
        if wc != nil {
            closeWindow()
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
            let clickedFolder = node.folder
            if clickedFolder != nil {
                _ = juggler!.open(link: clickedFolder!)
            }
        }
    }
    
    @IBAction func revealSelected(_ sender: Any) {
        for index in 0..<outlineView.numberOfRows {
            guard outlineView.isRowSelected(index) else { continue }
            guard let node = outlineView.item(atRow: index) as? NotenikFolderNode else {
                continue
            }
            guard node.type == .folder else { continue }
            let selFolder = node.folder
            if selFolder != nil {
                _ = NSWorkspace.shared.openFile(selFolder!.path)
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
        let parentWC = juggler!.openParentRealm()
        if parentWC != nil {
            closeWindow()
        }
    }
    
    
    @IBAction func newCollection(_ sender: Any) {
        guard juggler != nil else { return }
        let folderName = StringUtils.trim(newICloudFolderName.stringValue)
        if folderName.count == 0 {
            juggler!.userRequestsNewCollection()
        } else {
            let (url, errorMsg) = NotenikFolderList.shared.createNewFolderWithinICloudContainer(folderName: folderName)
            if url != nil {
                juggler!.proceedWithSelectedURL(requestType: .new, fileURL: url!)
            } else if errorMsg != nil {
                communicateError(errorMsg!, alert: true)
            }
        }
    }
    
    @IBAction func deleteSelected(_ sender: Any) {
        guard juggler != nil else { return }
        for index in 0..<outlineView.numberOfRows {
            guard outlineView.isRowSelected(index) else { continue }
            guard let node = outlineView.item(atRow: index) as? NotenikFolderNode else {
                continue
            }
            guard node.type == .folder else { continue }
            if node.folder!.location == .appBundle { continue }
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
                        try FileManager.default.removeItem(at: selFolder!.url!)
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

//
//  NewCollectionViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/7/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

/// Controls the overall tabbed view walking the user through the steps of creating a new collection. 
class NewCollectionViewController: NSTabViewController {
    
    let fm = FileManager.default
    
    let location = "Location"
    let name     = "Name"
    let fields   = "Fields"
    
    var lastTab  = ""
    
    let juggler = CollectionJuggler.shared
    
    var wc: NewCollectionWindowController!
    
    var locationVC: NewLocationViewController!
    var nameVC:     NewNameViewController!
    var fieldsVC:   NewFieldsViewController!
    
    var parentInICloud = false
    var parentURL: URL?
    
    var collectionName = ""
    var collectionURL: URL?
    var collectionPath = ""
    var folderCreated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationVC = (tabViewItems[0].viewController as! NewLocationViewController)
        locationVC.tabsVC = self
        
        nameVC = (tabViewItems[1].viewController as! NewNameViewController)
        nameVC.tabsVC = self
        
        fieldsVC = (tabViewItems[2].viewController as! NewFieldsViewController)
        fieldsVC.tabsVC = self
        
        self.selectedTabViewItemIndex = 0
    }
    
    /// Called to programatically change the tab selection via next/back buttons.
    func selectTab(index: Int) {
        self.selectedTabViewItemIndex = index
    }
    
    /// The user is requesting a tab to be displayed.
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        let go = super.tabView(tabView, shouldSelect: tabViewItem)
        guard go else { return go }
        guard let tab = tabViewItem else { return go }
        switch tab.label {
        case location:
            lastTab = tab.label
            return go
        case name:
            if parentURL == nil
                && locationVC.parentInICloud
                && NotenikFolderList.shared.iCloudContainerURL == nil {
                communicateError("iCloud Container is not available", alert: true)
                locationVC.userSelectedParent.state = .on
                return false
            }
            if lastTab == location || parentURL == nil {
                determineLocation()
            }
            if parentURL != nil {
                nameVC.setParent(parentURL!)
            }
            lastTab = tab.label
            return parentURL != nil
        case fields:
            if parentURL == nil {
                determineLocation()
            }
            if parentURL == nil {
                lastTab = tab.label
                return false
            }
            determineName()
            lastTab = tab.label
            if !folderCreated {
                return false
            }
        default:
            lastTab = tab.label
            return go
        }
        return go
    }
    
    func determineLocation() {
        parentURL = nil
        parentInICloud = locationVC.parentInICloud
        if parentInICloud {
            parentURL = NotenikFolderList.shared.iCloudContainerURL
        } else {
            parentURL = letUserPickParent()
        }
    }
    
    func letUserPickParent() -> URL? {
        
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a parent Folder"
        dialog.message = "Choose the Location for your Collection(s)"
        dialog.prompt                  = "Choose Parent Folder"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = true
        
        let response = dialog.runModal()
         
        if response == .OK {
            MultiFileIO.shared.registerBookmark(url: dialog.url!)
            return dialog.url
        } else {
            return nil
        }
    }
    
    func determineName() {

        folderCreated = false
        collectionName = nameVC.collectionName
        collectionURL = nil
        guard collectionName.count > 0 else {
            communicateError("You must specify a folder name before proceeding", alert: true)
            return
        }
        
        collectionURL = parentURL!.appendingPathComponent(collectionName)
        collectionPath = collectionURL!.path
        
        if FileUtils.isDir(collectionPath) && FileUtils.isEmpty(collectionPath) {
            folderCreated = true
        } else if parentInICloud {
            folderCreated = newCollectionInICloud()
        } else {
            folderCreated = newCollectionElsewhere()
        }
        
    }
    
    func newCollectionInICloud() -> Bool {
        
        var errorMsg: String?
        (collectionURL, errorMsg) = NotenikFolderList.shared.createNewFolderWithinICloudContainer(folderName: collectionName)
        if collectionURL == nil {
            if errorMsg != nil {
                communicateError(errorMsg!, alert: true)
                return false
            } else {
                communicateError("Problems creating new folder in the iCloud container", alert: true)
                return false
            }
        }
        return true
    }
    
    /// Create a folder for a new Collection within the specified parent folder.
    public func newCollectionElsewhere() -> Bool {

        collectionURL = parentURL!.appendingPathComponent(collectionName)
        guard !fm.fileExists(atPath: collectionURL!.path) else {
            communicateError("Folder named \(collectionName) already exists within the Parent folder", alert: true)
            return false
        }
        do {
            try fm.createDirectory(at: collectionURL!, withIntermediateDirectories: false, attributes: nil)
        } catch {
            communicateError("Could not create new collection at \(collectionURL!.path)")
            return false
        }
        return true
    }
    
    /// Collect the info gathered on the third tab, and now take action.
    func setFields(_ modelName: String, modelURL: URL) {
        
        guard let toURL = collectionURL else {
            communicateError("Name for new Collection must be specified first", alert: true)
            selectTab(index: 1)
            return
        }
        
        var ok = true
        var projectFolder = false
        var primaryFolder = ""
        switch modelName {
        case "11 - Commonplace with Lookups":
            projectFolder = true
            primaryFolder = "book"
        case "12 - Website":
            projectFolder = true
            primaryFolder = "content"
        case "16 - HTML for People demo":
            projectFolder = true
            primaryFolder = "content"
        default:
            break
        }
        
        if projectFolder {
            ok = copyFolders(fromURL: modelURL, toURL: toURL)
            logInfo(msg: "Copying folders")
        } else {
            logInfo(msg: "Relocating Collection")
            let relo = CollectionRelocation()
            ok = relo.copyOrMoveCollection(from: modelURL.path, to: toURL.path, move: false)
        }
        guard ok else {
            communicateError("Could not populate new Collection with model folder", alert: true)
            closeWindow()
            return
        }
        
        var wc: CollectionWindowController?
        let notesURL: URL? = toURL
        if projectFolder {
            logInfo(msg: "Opening project folder")
            _ = juggler.openParentRealm(parentURL: toURL)
            /* notesURL = URL(string: primaryFolder, relativeTo: toURL)
            wc = juggler.openFileWithNewWindow(fileURL: notesURL!, readOnly: false)
            if let readmeURL = URL(string: "README.md", relativeTo: toURL) {
                NSWorkspace.shared.open(readmeURL)
            } */
        } else {
            wc = juggler.openFileWithNewWindow(fileURL: toURL, readOnly: false)
        }
        guard notesURL != nil else { return }
        
        if wc != nil {
            juggler.notenikFolderList.add(url: notesURL!, type: .ordinaryCollection, location: .undetermined)
            let io = wc!.io
            if io != nil {
                let collection = io!.collection
                if collection != nil {
                    collection!.setDefaultTitle()
                    if collection!.mirror != nil {
                        wc!.mirrorAllNotesAndIndex(self)
                    }
                }
            }
            wc!.menuCollectionPreferences(self)
        }
        
        closeWindow()
    }
    
    func copyFolders(fromURL: URL, toURL: URL) -> Bool {
        var ok = FileUtils.ensureFolder(forURL: toURL)
        if ok {
            do {
                let items = try fm.contentsOfDirectory(at: fromURL, includingPropertiesForKeys: nil)
                for item in items {
                    let itemName = item.lastPathComponent
                    guard let toURL = URL(string: itemName, relativeTo: toURL) else { continue }
                    try fm.copyItem(at: item, to: toURL)
                }
            } catch {
                communicateError("Errors copying folder from \(fromURL) to \(toURL)")
                ok = false
            }
        }
        return ok
    }
    
    func closeWindow() {
        wc.close()
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NewCollectionViewController",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NewCollectionViewController",
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

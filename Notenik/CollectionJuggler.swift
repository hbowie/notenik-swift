//
//  CollectionJuggler.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// A singleton object that controls all of the Note Collections that are open. 
class CollectionJuggler: NSObject, CollectionPrefsOwner {
    
    // Singleton instance
    static let shared = CollectionJuggler()
    
    // Shorthand references to System Objects
    private let defaults = UserDefaults.standard
    
    let storyboard:      NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    let logStoryboard:   NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    
    let osdir = OpenSaveDirectory.shared
    let essentialURLKey = "essential-collection"
    var essentialURL: URL?
    
    let lastURLKey = "last-collection"
    var lastURL: URL?
    
    var docController: NoteDocumentController?
    
    var windows: Array<CollectionWindowController> = Array()
    var highestWindowNumber = -1
    
    var initialWindow: CollectionWindowController?
    
    override private init() {
        super.init()
        essentialURL = defaults.url(forKey: essentialURLKey)
        lastURL = defaults.url(forKey: lastURLKey)
    }
    
    /// Startup called by AppDelegate
    func startup() {
        
        if let logController = self.logStoryboard.instantiateController(withIdentifier: "logWC") as? LogWindowController {
            Logger.shared.logDest = .window
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Log Window Controller! when loading initial collection")
        }
        
        loadInitialCollection()
    }
    
    /// The user has requested us to save the current collection in a new location
    func userRequestsSaveAs(currentIO: NotenikIO, currentWindow: CollectionWindow) {
        guard currentIO.collectionOpen else { return }
        
        // Ask the user for a new location on disk
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a New Location for this Notenik Folder"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.saveCollectionAs(currentIO: currentIO, currentWindow: currentWindow, newURL: openPanel.url!)
            }
        }
    }
    
    func saveCollectionAs(currentIO: NotenikIO, currentWindow: CollectionWindow, newURL: URL) -> Bool {
        guard currentIO.collectionOpen else { return false }
        guard let oldCollection = currentIO.collection else { return false }
        guard let oldURL = oldCollection.collectionFullPathURL else { return false }
        do {
            try FileManager.default.removeItem(at: newURL)
            try FileManager.default.copyItem(at: oldURL, to: newURL)
        } catch {
            Logger.shared.log(skip: true, indent: 0, level: .severe,
                              message: "Could not Save current Collection as a new folder")
            return false
        }
        
        let openOK = openFileWithNewWindow(fileURL: newURL, readOnly: false)
        
        if openOK {
            currentWindow.close()
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Retain the Original Collection?"
            alert.informativeText = "Collection originally located at \(oldURL.path) was successfully copied to \(newURL.path)"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "No - Trash It")
            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                do {
                    try FileManager.default.trashItem(at: oldURL, resultingItemURL: nil)
                } catch {
                    Logger.shared.log(skip: false, indent: 0, level: .severe,
                                      message: "Could not trash the Collection located at \(oldURL.path)")
                }
            }
        }
        
        return openOK
    }
    
    /// The user has indicated they'd like to create a new collection
    func userRequestsNewCollection() {
        
        // Ask the user for a location on disk
        let openPanel = NSOpenPanel();
        openPanel.title = "Create and Select a New Notenik Folder"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.newCollection(fileURL: openPanel.url!)
            }
        }
    }
    
    /// Now that we have a disk location, let's take other steps
    /// to create a new collection.
    func newCollection(fileURL: URL) -> Bool {
        
        // Create and populate a starting NoteCollection object
        var openOK = false
        
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        
        var collectionURL: URL
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        
        let initOK = io.initCollection(realm: realm, collectionPath: collectionURL.path)
        guard initOK else { return false }
        
        io.addDefaultDefinitions()
        
        // Now let the user tailor the starting Collection default values
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            collectionPrefsController.showWindow(self)
            collectionPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io.collection!)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Collection Prefs Window Controller!")
        }
        
        return openOK
    }
    
    /// Let the calling class know that the user has completed modifications
    /// of the Collection Preferences.
    ///
    /// - Parameters:
    ///   - ok: True if they clicked on OK, false if they clicked Cancel.
    ///   - collection: The Collection whose prefs are being modified.
    ///   - window: The Collection Prefs window.
    func collectionPrefsModified(ok: Bool,
                                 collection: NoteCollection,
                                 window: CollectionPrefsWindowController) {
        window.close()
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var ok = io.newCollection(collection: collection)
        guard ok else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.moderate,
                              message: "Problems initializing the new collection at " + collection.collectionFullPath)
            return
        }
        

        Logger.shared.log(skip: true, indent: 0, level: LogLevel.normal,
                              message: "New Collection successfully initialized at \(collection.collectionFullPath)")
        
        saveCollectionURLInfo(collectionURL: collection.collectionFullPathURL!)

        if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
            windowController.shouldCascadeWindows = true
            windowController.io = io
            self.registerWindow(window: windowController)
            windowController.showWindow(self)
            ok = true
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Window Controller!")
        }
    }
    
    /// Make the given collection the easily accessible Essential collection
    ///
    /// - Parameter io: The Notenik Input/Output module accessing the collection that is to become essential
    func makeCollectionEssential(io: NotenikIO) {
        let collection = io.collection
        if collection != nil {
            essentialURL = collection!.collectionFullPathURL
            if essentialURL != nil {
                defaults.set(essentialURL!, forKey: essentialURLKey)
            }
        }
    }
    
    /// Open the Essential Collection, if we have one
    func openEssentialCollection() {
        if essentialURL != nil {
            openFileWithNewWindow(fileURL: essentialURL!, readOnly: false)
        }
    }
    
    /// Open the Application's Internal Collection of Help Notes
    func openHelpNotes() {
        let path = Bundle.main.resourcePath! + "/notenik-swift-intro"
        openFileWithNewWindow(folderPath: path, readOnly: true)
    }
    
    /// Respond to a user request to open another Collection. Present the user
    /// with an Open Panel to allow the selection of a folder containing an
    /// existing Notenik Collection. 
    func userRequestsOpenCollection() {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Notenik Collection"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.openFileWithNewWindow(fileURL: openPanel.url!, readOnly: false)
            }
        }
    }
    
    /// Attempt to open a Notenik collection, starting with a file path.
    ///
    /// - Parameters:
    ///   - folderPath: The path to the collection folder.
    ///   - readOnly:   Should this collection be opened read-only?
    /// - Returns: True if open was successful; false otherwise.
    func openFileWithNewWindow(folderPath: String, readOnly: Bool) -> Bool {
        let fileURL = URL(fileURLWithPath: folderPath)
        return openFileWithNewWindow(fileURL: fileURL, readOnly: readOnly)
    }
    
    /// Attempt to open a Notenik Collection.
    ///
    /// - Parameter fileURL: A URL pointing to a Notenik folder.
    /// - Returns: True if open was successful, false if not.
    func openFileWithNewWindow(fileURL: URL, readOnly: Bool) -> Bool {
        var openOK = false
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var collectionURL: URL
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        let collection = io.openCollection(realm: realm, collectionPath: collectionURL.path)
        if collection == nil {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.moderate,
                              message: "Problems opening the collection at " + collectionURL.path)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.normal,
                              message: "Collection successfully opened: \(collection!.title)")
            collection!.readOnly = readOnly
            saveCollectionURLInfo(collectionURL: collectionURL)
            if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
                windowController.shouldCascadeWindows = true
                windowController.io = io
                self.registerWindow(window: windowController)
                windowController.showWindow(self)
                openOK = true
            } else {
                Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                                  message: "Couldn't get a Window Controller!")
            }
        }
        return openOK
    }
    
    /// Register a window so that we can keep track of it. If we've already got the window
    /// in our registry, then don't add a duplicate.
    ///
    /// - Parameter window: A Collection Window Controller.
    /// - Returns: A unique window number assigned to this window.
    func registerWindow(window: CollectionWindowController) {
        for nextWindow in windows {
            if nextWindow as AnyObject === window as AnyObject {
                return
            }
        }
        highestWindowNumber += 1
        window.windowNumber = highestWindowNumber
        self.windows.append(window)
        if self.windows.count > 1 {
            let oldWindow = self.windows[self.windows.count - 2]
            let oldWindowPosition = oldWindow.window?.frame
            let newWindowPosition = oldWindowPosition?.offsetBy(dx: 50, dy: -50)
            if (newWindowPosition != nil) {
                window.window?.setFrame(newWindowPosition!, display: true)
            }
        }
        if window.windowNumber == 0 && window.io == nil {
            initialWindow = window
        }
    }
    
    /// Find a collection to show in the initial window shown upon application launch.
    ///
    /// - Parameter window: <#window description#>
    func loadInitialCollection() {
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        print ("Home Directory for current user is \(home)")
        
        // Figure out a good collection to open
        var io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var collection: NoteCollection?
        var collectionURL: URL?

        if essentialURL != nil {
            collectionURL = essentialURL
            collection = io.openCollection(realm: realm, collectionPath: essentialURL!.path)
        }

        if collection == nil && lastURL != nil {
            collectionURL = lastURL
            collection = io.openCollection(realm: realm, collectionPath: lastURL!.path)
        }
        
        if collection != nil {
            saveCollectionURLInfo(collectionURL: collectionURL!)
        }

        if collection == nil {
            let path = Bundle.main.resourcePath! + "/notenik-swift-intro"
            collection = io.openCollection(realm: realm, collectionPath: path)
        }
        
        initialWindow!.io = io
    }
    
    /// Once we've opened a collection, save some info about it so we can use it later
    func saveCollectionURLInfo(collectionURL: URL) {
        if self.docController != nil {
            self.docController!.noteNewRecentDocumentURL(collectionURL)
        }
        defaults.set(collectionURL, forKey: lastURLKey)
        self.osdir.lastParentFolder = collectionURL.deletingLastPathComponent()
    }

}

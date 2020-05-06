//
//  CollectionJuggler.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

/// A singleton object that controls all of the Note Collections that are open. 
class CollectionJuggler: NSObject, CollectionPrefsOwner {
    
    let notenikSwiftIntroPath = "/notenik-swift-intro"
    
    // Singleton instance
    static let shared = CollectionJuggler()
    
    // Shorthand references to System Objects
    private let defaults = UserDefaults.standard
    
    var cloudNik: CloudNik!
    var knownFolders: KnownFolders!
    
    let appPrefs  = AppPrefs.shared
    let osdir     = OpenSaveDirectory.shared
    
    let storyboard:      NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    let logStoryboard:   NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    
    let scriptStoryboard: NSStoryboard = NSStoryboard(name: "Script", bundle: nil)
    var scriptWindowController: ScriptWindowController?
    
    let collectorStoryboard: NSStoryboard = NSStoryboard(name: "Collector", bundle: nil)
    var collectorWindowController: CollectorWindowController?
    
    var docController: NoteDocumentController?
    
    var windows: Array<CollectionWindowController> = Array()
    var highestWindowNumber = -1
    
    var initialWindow: CollectionWindowController?
    var initialWindowUsed = false
    
    override private init() {
        super.init()
        // cloudNik = CloudNik.shared
    }
    
    /// Startup called by AppDelegate
    func startup() {
        if self.logStoryboard.instantiateController(withIdentifier: "logWC") is LogWindowController {
            Logger.shared.logDestWindow = true
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Couldn't get a Log Window Controller! at startup")
        }
        knownFolders = KnownFolders.shared
    }
    
    func makeRecentDocsKnown(_ recentDocumentURLs: [URL]) {
        for url in recentDocumentURLs {
            knownFolders.add(url: url, isCollection: true, fromBookmark: false, suspendReload: true)
        }
        knownFolders.reload()
    }
    
    func loadBookmarkDefaults() {
        knownFolders.loadBookmarkDefaults()
    }
    
    /// Find a collection to show in the initial window shown upon application launch.
    func loadInitialCollection() {
        
        // Figure out a good collection to open
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var collection: NoteCollection?

        if appPrefs.essentialURL != nil {
            collection = io.openCollection(realm: realm, collectionPath: appPrefs.essentialURL!.path)
        }

        if collection == nil && appPrefs.lastURL != nil {
            collection = io.openCollection(realm: realm, collectionPath: appPrefs.lastURL!.path)
        }
        
        if collection != nil {
            saveCollectionInfo(collection!)
            KnownFolders.shared.add(collection!, suspendReload: false)
        }

        if collection == nil {
            let path = Bundle.main.resourcePath! + notenikSwiftIntroPath
            collection = io.openCollection(realm: realm, collectionPath: path)
            collection?.readOnly = true
        }
        
        _ = assignIOtoWindow(io: io)
    }
    
    /// Figure out what to do with a bunch of passed URLs.
    func open(urls: [URL]) -> Int {
        let tempIO = FileIO()
        var successfulOpens = 0
        for url in urls {
            let type = tempIO.checkPathType(path: url.path)
            switch type {
            case .empty:
                let ok = newCollection(fileURL: url)
                if ok {
                    successfulOpens += 1
                }
            case .existing:
                let ok = openFileWithNewWindow(fileURL: url, readOnly: false)
                if ok {
                    successfulOpens += 1
                }
            case .hopeless:
                communicateError("Item to be opened at \(url.path) could not be used",
                alert: true)
            case .realm:
                openParentRealm(parentURL: url)
                successfulOpens += 1
            }
        }
        return successfulOpens
    }
    
    /// Respond to a user request to create a new collection
    func userRequestsNewCollection() {
        selectCollection(requestType: .new)
    }
    
    /// Display the Bookmarks Window.
    func displayBookmarksBoard() {
        if collectorWindowController == nil {
            collectorWindowController = collectorStoryboard.instantiateController(withIdentifier: "collectorWC") as? CollectorWindowController
        }
        if collectorWindowController == nil {
            communicateError("Couldn't get a Collector Window Controller")
        } else {
            collectorWindowController!.showWindow(self)
            collectorWindowController!.passCollectorRequesterInfo(juggler: self,
                                                                  tree: knownFolders)
        }
    }
    
    /// Let the user select a Collection to be opened
    func selectCollection(requestType: CollectionRequestType) {
        let openPanel = prepCollectionOpenPanel()
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.proceedWithSelectedURL(requestType: requestType, fileURL: openPanel.url!)
            }
        }
    }
    
    /// Proceed with the user request, now that we have a URL
    func proceedWithSelectedURL(requestType: CollectionRequestType, fileURL: URL) {
        KnownFolders.shared.add(url: fileURL,
                                isCollection: true,
                                fromBookmark: false,
                                suspendReload: false)
        if requestType == .new {
            _ = newCollection(fileURL: fileURL)
        }
    }
    
    /// Open a Parent Folder containing one or more Notenik Collections
    func openParentRealm() {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Parent Folder containing one or more Collections"
        if appPrefs.parentRealmParentURL != nil {
            openPanel.directoryURL = appPrefs.parentRealmParentURL!
        } else {
            openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.openParentRealm(parentURL: openPanel.url!)
            }
        }
    }
    
    func openParentRealm(parentURL: URL) {
        KnownFolders.shared.add(url: parentURL,
                                isCollection: false,
                                fromBookmark: false,
                                suspendReload: false)
        AppPrefs.shared.parentRealmPath = parentURL.path
        appPrefs.parentRealmParentURL = parentURL.deletingLastPathComponent()
        let realmScanner = RealmScanner()
        realmScanner.openRealm(path: parentURL.path)
        let io = realmScanner.realmIO
        _ = assignIOtoWindow(io: io)
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
                _ = self.saveCollectionAs(currentIO: currentIO, currentWindow: currentWindow, newURL: openPanel.url!)
            }
        }
    }
    
    /// Save the User's Collection in a new location
    func saveCollectionAs(currentIO: NotenikIO, currentWindow: CollectionWindow, newURL: URL) -> Bool {
        guard currentIO.collectionOpen else { return false }
        guard let oldCollection = currentIO.collection else { return false }
        guard let oldURL = oldCollection.collectionFullPathURL else { return false }
        let newFileName = FileName(newURL)
        let newFolderNameLower = newFileName.folder.lowercased()
        if newFolderNameLower == "desktop" || newFolderNameLower == "documents" {
            communicateError("Please create a folder within the \(newFileName.folder) folder", alert: true)
            return false
        }
        do {
            let items = try  FileManager.default.contentsOfDirectory(atPath: newURL.path)
            if items.count > 0 {
                communicateError("New folder location at \(newURL.path) already contains other files", alert: true)
                return false
            }
        } catch {
            communicateError("Could not access contents of directory at \(newURL.path)")
            return false
        }
        do {
            try FileManager.default.removeItem(at: newURL)
            try FileManager.default.copyItem(at: oldURL, to: newURL)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Could not Save current Collection as a new folder")
            return false
        }
        
        let openOK = openFileWithNewWindow(fileURL: newURL, readOnly: false)
        
        if openOK {
            KnownFolders.shared.add(url: newURL,
                                    isCollection: true,
                                    fromBookmark: false,
                                    suspendReload: false)
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
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "CollectionJuggler",
                                      level: .error,
                                      message: "Could not trash the Collection located at \(oldURL.path)")
                }
            }
        }
        
        return openOK
    }
    
    /// User clicked Cancel on the Parent Location Window
    func parentLocationCancel() {
        // Apparently we're done
    }
    
    /// Prep an Open Panel to use for selecting/creating a Collection folder
    func prepCollectionOpenPanel() -> NSOpenPanel {
        
        let openPanel = NSOpenPanel();
        openPanel.title = "Create and Select a New Notenik Folder"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        // openPanel.directoryURL = home
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        return openPanel
    }
    
    func newFolder(folderURL: URL) -> Bool {
        print("CollectionJuggler.newFolder")
        print("  - folder url = \(folderURL.absoluteString)")
        let folderPath = folderURL.path
        print("  - folder path = \(folderPath)")
        let alreadyExists = FileManager.default.fileExists(atPath: folderPath)
        print("  - Folder already exists? \(alreadyExists)")
        guard !alreadyExists else { return false }
        do {
            try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("  - Attempt to create new directory failed!")
            return false
        }
        return true
    }
    
    /// Now that we have a disk location, let's take other steps
    /// to create a new collection.
    func newCollection(fileURL: URL) -> Bool {
        
        // Create and populate a starting NoteCollection object
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
        
        KnownFolders.shared.add(url: collectionURL,
                                isCollection: true,
                                fromBookmark: false,
                                suspendReload: false)
        io.addDefaultDefinitions()
        
        // Now let the user tailor the starting Collection default values
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            collectionPrefsController.showWindow(self)
            collectionPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io.collection!)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Couldn't get a Collection Prefs Window Controller!")
            return false
        }
        
        return true
    }
    
    
    /// Increase the font size used on the Edit panel
    func viewIncreaseEditFontSize() {
        appPrefs.increaseEditFontSize(by: 1.0)
        adjustEditWindows()
    }
    
    /// Decrease the font size used on the Edit Panel
    func viewDecreaseEditFontSize() {
        appPrefs.decreaseEditFontSize(by: 1.0)
        adjustEditWindows()
    }
    
    func viewResetEditFontSize() {
        appPrefs.resetEditFontSize()
        adjustEditWindows()
    }
    
    /// Adjust all the open windows to reflect any changes in the UI appearance.
    func adjustEditWindows() {
        for window in windows {
            window.editVC!.containerViewBuilt = false
            window.editVC!.makeEditView()
            window.editVC!.populateFieldsWithSelectedNote()
        }
    }
    
    func displayRefresh() {
        for window in windows {
            window.reloadDisplayView(self)
        }
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
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "MergeInput",
                              level: .error,
                              message: "Problems initializing the new collection at " + collection.collectionFullPath)
            return
        }
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionJuggler",
                          level: .info,
                          message: "New Collection successfully initialized at \(collection.collectionFullPath)")
        
        saveCollectionInfo(collection)

        ok = assignIOtoWindow(io: io)
    }
    
    /// Make the given collection the easily accessible Essential collection
    ///
    /// - Parameter io: The Notenik Input/Output module accessing the collection that is to become essential
    func makeCollectionEssential(io: NotenikIO) {
        guard let collection = io.collection else { return }
        guard let collectionURL = collection.collectionFullPathURL else { return }
        appPrefs.essentialURL = collectionURL
    }
    
    /// Open the Essential Collection, if we have one
    func openEssentialCollection() {
        guard let essentialURL = appPrefs.essentialURL else { return }
        KnownFolders.shared.add(url: essentialURL,
                                isCollection: true,
                                fromBookmark: false,
                                suspendReload: false)
        _ = openFileWithNewWindow(fileURL: essentialURL, readOnly: false)
    }
    
    /// Open the Application's Internal Collection of Help Notes
    func openHelpNotes() {
        let path = Bundle.main.resourcePath! + notenikSwiftIntroPath
        _ = openFileWithNewWindow(folderPath: path, readOnly: true)
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
                _ = self.openFileWithNewWindow(fileURL: openPanel.url!, readOnly: false)
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
        
        // If the collection is already open, then simply bring
        // that window to the front.
        for window in windows {
            if let windowURL = window.io?.collection?.collectionFullPathURL {
                if windowURL == collectionURL && window.window != nil {
                    window.window!.makeKeyAndOrderFront(self)
                    return true
                }
            }
        }
        
        let collection = io.openCollection(realm: realm, collectionPath: collectionURL.path)
        if collection == nil {
            communicateError("Problems opening the collection at " + collectionURL.path,
                             alert: true)  
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .info,
                              message: "Collection successfully opened: \(collection!.title)")
            collection!.readOnly = readOnly
            saveCollectionInfo(collection!)
            openOK = assignIOtoWindow(io: io)
        }
        KnownFolders.shared.add(collection!, suspendReload: false)
        return openOK
    }
    
    /// Assign an Input/Output module to a new or existing window.
    /// - Parameter io: An I/O module already opened with a Collection.
    func assignIOtoWindow(io: NotenikIO) -> Bool {
        var ok = true
        if initialWindowUsed {
            if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
                windowController.shouldCascadeWindows = true
                windowController.io = io
                self.registerWindow(window: windowController)
                windowController.showWindow(self)
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionJuggler",
                                  level: .error,
                                  message: "Couldn't get a Window Controller!")
                ok = false
            }
        } else {
            initialWindow!.io = io
            initialWindowUsed = true
        }
        return ok
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
    
    /// Once we've opened a collection, save some info about it so we can use it later
    func saveCollectionInfo(_ collection: NoteCollection) {
        guard let collectionURL = collection.collectionFullPathURL else { return }
        if self.docController != nil {
            self.docController!.noteNewRecentDocumentURL(collectionURL)
        }
        appPrefs.lastURL = collectionURL
        self.osdir.lastParentFolder = collectionURL.deletingLastPathComponent()
    }
    
    /// Allow the user to select a script file to be played.
    func scriptOpen() {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Script File to be Played"
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                self.launchScript(fileURL: openPanel.url!)
            }
        }
    }
    
    /// Launch a script to be played.
    func launchScript(fileURL: URL) {
        ensureScriptController()
        guard scriptWindowController != nil else { return }
        scriptWindowController!.showWindow(self)
        scriptWindowController!.scriptOpenInput(fileURL)
    }
    
    func showScriptWindow() {
        ensureScriptController()
        guard scriptWindowController != nil else { return }
        // scriptController!.selectScriptTab()
        scriptWindowController!.showWindow(self)
    }
    
    func ensureScriptController() {
        if scriptWindowController == nil {
            scriptWindowController = scriptStoryboard.instantiateController(withIdentifier: "scriptWC") as? ScriptWindowController
        }
        if scriptWindowController == nil {
            communicateError("Couldn't get a Script Window Controller")
        }
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionJuggler",
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

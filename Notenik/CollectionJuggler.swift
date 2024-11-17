//
//  CollectionJuggler.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

/// A singleton object that controls all of the Note Collections that are open. 
class CollectionJuggler: NSObject {
    
    // Singleton instance
    static let shared = CollectionJuggler()
    
    // Shorthand references to System Objects
    private let defaults = UserDefaults.standard
    let application = NSApplication.shared
    let fm = FileManager.default
    
    let multi = MultiFileIO.shared
    
    var notenikFolderList: NotenikFolderList!
    
    let appPrefs  = AppPrefs.shared
    let appPrefsCocoa = AppPrefsCocoa.shared
    let osdir     = OpenSaveDirectory.shared
    var sortMenu: NSMenu!
    var displayModeMenu: NSMenu!
    var showHideOutline: NSMenuItem!
    
    let modelsPath = "/models"
    let notenikSupport = "com.powersurgepub.notenik.macos"
    let styleSheets = "Style Sheets"
    let introModelPath = "/02 - Notenik Intro"
    var introModelFullPath = ""

    let introFolderName = "Intro"
    
    let storyboard:                NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    let logStoryboard:             NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    let prefsStoryboard:           NSStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    let navStoryboard:             NSStoryboard = NSStoryboard(name: "Navigator", bundle: nil)
    let quickActionStoryBoard:     NSStoryboard = NSStoryboard(name: "QuickAction", bundle: nil)
    
    let scriptStoryboard: NSStoryboard = NSStoryboard(name: "Script", bundle: nil)
    var scriptWindowController: ScriptWindowController?
    
    var lastScript: URL?
    
    var docController: NoteDocumentController?
    
    var windows: Array<CollectionWindowController> = Array()
    var highestWindowNumber = -1
    
    var initialWindow: CollectionWindowController?
    var initialWindowUsed = false
    
    var navController: NavigatorWindowController?
    var quickActionController: QuickActionWindowController?
    
    var lastSelectedNoteTitle = ""
    var lastSelectedNoteCustomURL = ""
    var lastSelectedNoteFilepath = ""
    
    override private init() {
        super.init()
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
        notenikFolderList = NotenikFolderList.shared
    }
    
    func appSupport() {
        
        let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let notenikSupportURL = appSupportURL.appendingPathComponent(notenikSupport)
        let styleSheetsURL = notenikSupportURL.appendingPathComponent(styleSheets)
        let styleSheetsPath = styleSheetsURL.relativePath
        if fm.fileExists(atPath: styleSheetsPath) {
            
        } else {
            do {
                try fm.createDirectory(atPath: styleSheetsPath, withIntermediateDirectories: true)
            } catch {
                print("error creating directory")
            }
        }
    }
    
    func makeRecentDocsKnown(_ recentDocumentURLs: [URL]) {
        for url in recentDocumentURLs {
            notenikFolderList.add(url: url, type: .ordinaryCollection, location: .undetermined)
        }
    }
    
    /// Find a collection to show in the initial window shown upon application launch.
    func loadInitialCollection() {
        
        var collection: NoteCollection?
        var io = FileIO()
        
        let collector = NoteCollector()
        
        if let url = appPrefs.essentialURL {
            (collection, io) = multi.provision(collectionPath: url.path,
                                               inspector: collector,
                                               readOnly: false)
        }
        
        if collection == nil {
            if let url = appPrefs.lastURL {
                (collection, io) = multi.provision(collectionPath: url.path,
                                                   inspector: collector,
                                                   readOnly: false)
            }
        }
        
        if collection == nil {
            let collectionPath = loadNotenikIntro()
            if !collectionPath.isEmpty {
                (collection, io) = multi.provision(collectionPath: collectionPath, inspector: nil, readOnly: false)
                _ = io.firstNote()
            }
        }
        
        if collection != nil {
            saveCollectionInfo(collection!)
            notenikFolderList.add(collection!)
        }

        if collection == nil {
            let path = notenikFolderList.kbNode.folder!.path
            (collection, io) = multi.provision(collectionPath: path, inspector: nil, readOnly: true)
            _ = io.firstNote()
        }
        
        let wc = assignIOtoWindow(io: io)
        if wc != nil {
            if collection != nil && !collection!.readOnly {
                if collection!.startupToday {
                    if appPrefs.networkAvailable {
                        wc!.launchLinks(collector)
                        collection!.startedUp()
                        io.persistCollectionInfo()
                    }
                }
            }
        }
    }
    
    func checkGrantAndLoadShortcuts() {
        let grantAccessOpt = appPrefs.grantAccessOption
        if grantAccessOpt > 1 {
            let confirmDialog = (grantAccessOpt == 2)
            grantFolderAccess(confirm: confirmDialog)
        }
        NotenikFolderList.shared.loadShortcutsFromPrefs()
    }
    
    func loadNotenikIntro() -> String {
        guard notenikFolderList.iCloudContainerAvailable else { return "" }
        guard let iCloudContainer = notenikFolderList.iCloudContainerURL else { return "" }
        let introURL = iCloudContainer.appendingPathComponent(introFolderName)
        guard !fm.fileExists(atPath: introURL.path) else { return "" }
        let (collectionURL, _) = notenikFolderList.createNewFolderWithinICloudContainer(folderName: introFolderName)
        guard collectionURL != nil else { return "" }
        introModelFullPath = Bundle.main.resourcePath! + modelsPath + introModelPath
        let relo = CollectionRelocation()
        let ok = relo.copyOrMoveCollection(from: introModelFullPath, to: collectionURL!.path, move: false)
        guard ok else { return "" }
        return collectionURL!.path
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Open a folder.
    //
    // -----------------------------------------------------------
    
    /// Let the user select a folder to be opened.
    func openFolder() -> Bool {
        var opens = 0
        let openPanel = prepCollectionOpenPanel()
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            opens = open(urls: [openPanel.url!])
        }
        return opens > 0
    }
    
    /// Figure out what to do with a bunch of passed URLs.
    func open(urls: [URL]) -> Int {
        var successfulOpens = 0
        for url in urls {
            let ok = open(url: url)
            if ok {
                successfulOpens += 1
            }
        }
        return successfulOpens
    }
    
    /// Open a single URL.
    func open(url: URL) -> Bool {
        var link: NotenikLink?
        var readable = true
        var folderURL: URL?
        if url.scheme == "file" {
            if url.pathExtension == NotenikConstants.infoFileExt {
                folderURL = url.deletingLastPathComponent()
            } else {
                folderURL = url
            }
            let folderPath = folderURL!.path
            readable = fm.isReadableFile(atPath: folderPath)
            link = NotenikLink(url: folderURL!)
        } else {
            link = NotenikLink(url: url)
        }
        if !readable {
            communicateError("You will need to explicitly open this folder since Notenik does not currently have access to it.", alert: true)
            link = explicitFolderOpen(requestedParent: folderURL!.deletingLastPathComponent())
        }
        guard link != nil else { return false }
        // link!.determineCollectionType()
        let wc = open(link: link!)
        guard wc != nil else { return false }
        return true
    }
    
    func explicitFolderOpen(requestedParent: URL) -> NotenikLink? {
        let openPanel = NSOpenPanel();
        openPanel.title = "Open a Notenik Folder"
        openPanel.directoryURL = requestedParent
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let result = openPanel.runModal()
        guard result == .OK else { return nil }
        guard let folder = openPanel.url else { return nil }
        return NotenikLink(url: folder)
    }
    
    /// Open a single NotenikLink. 
    func open(link: NotenikLink) -> CollectionWindowController? {
        
        guard link.location != .appBundle else {
            return openFileWithNewWindow(fileURL: link.url!, readOnly: true)
        }
        link.determineCollectionType()
        switch link.type {
        case .accessFolder:
            accessGranted(accessFolder: link.url)
        case .emptyFolder:
            return newCollection(fileURL: link.url!)
        case .ordinaryCollection, .webCollection:
            return openFileWithNewWindow(fileURL: link.url!, readOnly: false)
        case .parentRealm:
            return openParentRealm(parentURL: link.url!)
        case .notenikScheme:
            let actor = CustomURLActor()
            _ = actor.act(on: link.str)
        case .noteFile:
            _ = openNoteFile(link: link)
        default:
            communicateError("Item to be opened at \(link) could not be used, possibly due to expired permissions", alert: true)
        }
        return nil
    }
    
    func userRequestsNewWebsite() {
        selectCollection(requestType: .newWebsite)
    }
    
    /// Respond to a user request to create a new collection
    func userRequestsNewCollection() {
        selectCollection(requestType: .new)
    }
        
    /// Let the user select a Collection to be opened
    func selectCollection(requestType: CollectionRequestType) {
        let openPanel = prepCollectionOpenPanel()
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            proceedWithSelectedURL(requestType: requestType, fileURL: openPanel.url!)
        }
    }
    
    func newCollectionInICloud(folderName: String) -> Bool {
        let folderTrimmed = StringUtils.trim(folderName)
        guard folderTrimmed.count > 0 else {
            communicateError("New Folder Name is blank", alert: true)
            return false
        }
        let (url, errorMsg) = NotenikFolderList.shared.createNewFolderWithinICloudContainer(folderName: folderTrimmed)
        guard url != nil else {
            if errorMsg == nil {
                communicateError("Problems creating new folder in the iCloud container", alert: true)
                return false
            } else {
                communicateError(errorMsg!, alert: true)
                return false
            }
        }
        proceedWithSelectedURL(requestType: .new, fileURL: url!)
        return true
    }
    
    /// Proceed with the user request, now that we have a URL
    func proceedWithSelectedURL(requestType: CollectionRequestType, fileURL: URL) {
        notenikFolderList.add(url: fileURL, type: .ordinaryCollection, location: .undetermined)
        if requestType == .new {
            _ = newCollection(fileURL: fileURL)
        } else if requestType == .newWebsite {
            _ = newWebsite(fileURL: fileURL)
        }
    }
    
    /// Open a Parent Folder containing one or more Notenik Collections
    func openParentRealm() -> CollectionWindowController? {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Project Folder containing one or more Collections"
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
        openPanel.prompt = "Open Project"
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            return self.openParentRealm(parentURL: openPanel.url!)
        }
        return nil
    }
    
    /// Open a parent realm containing one or more Notenik Collections.
    func openParentRealm(parentURL: URL) -> CollectionWindowController? {
        
        // If the collection is already open, then close it before
        // we re-open it.
        for window in windows {
            guard let windowCollection = window.io?.collection else { continue }
            guard let windowURL = windowCollection.fullPathURL else { continue }
            if windowURL == parentURL && window.window != nil {
                window.window!.close()
                break
            }
        }
        
        notenikFolderList.add(url: parentURL, type: .parentRealm, location: .undetermined)
        AppPrefs.shared.parentRealmPath = parentURL.path
        appPrefs.parentRealmParentURL = parentURL.deletingLastPathComponent()
        let realmScanner = RealmScanner()
        let ok = realmScanner.openRealm(path: parentURL.path)
        if ok {
            if self.docController != nil {
                self.docController!.noteNewRecentDocumentURL(parentURL)
            }
            let io = realmScanner.realmIO
            return assignIOtoWindow(io: io)
        }
        return nil
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
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            _ = self.saveCollectionAs(currentIO: currentIO, currentWindow: currentWindow, newURL: openPanel.url!)
        }
    }
    
    /// Save the User's Collection in a new location
    func saveCollectionAs(currentIO: NotenikIO, currentWindow: CollectionWindow, newURL: URL) -> Bool {
        guard currentIO.collectionOpen else { return false }
        guard let oldCollection = currentIO.collection else { return false }
        guard let oldURL = oldCollection.fullPathURL else { return false }
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
        
        let wc = openFileWithNewWindow(fileURL: newURL, readOnly: false)
        
        if wc != nil {
            notenikFolderList.add(url: newURL, type: .ordinaryCollection, location: .undetermined)
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
        
        return (wc != nil)
    }
    
    /// Move the indicated Collection to a new Location.
    func userRequestsMove(currentIO: NotenikIO, currentWindow: CollectionWindow) {
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
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            _ = self.moveCollection(currentIO: currentIO, currentWindow: currentWindow, newURL: openPanel.url!)
        }
    }
    
    /// Move the User's Collection to a new location
    func moveCollection(currentIO: NotenikIO, currentWindow: CollectionWindow, newURL: URL) -> Bool {
        guard currentIO.collectionOpen else { return false }
        guard let oldCollection = currentIO.collection else { return false }
        guard let oldURL = oldCollection.fullPathURL else { return false }
        let newFileName = FileName(newURL)
        let newFolderNameLower = newFileName.folder.lowercased()
        if newFolderNameLower == "desktop" || newFolderNameLower == "documents" {
            communicateError("Please create a folder within the \(newFileName.folder) folder", alert: true)
            return false
        }
        let empty = FileUtils.isEmpty(newURL.path)
        if !empty {
            communicateError("New folder location at \(newURL.path) already contains other files", alert: true)
            return false
        }
        let relo = CollectionRelocation()
        let ok = relo.copyOrMoveCollection(from: oldURL.path, to: newURL.path, move: true)
        if !ok {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Could not Move current Collection to a new folder")
            return false
        }
        
        let wc = openFileWithNewWindow(fileURL: newURL, readOnly: false)
        
        if wc != nil {
            notenikFolderList.add(url: newURL, type: .ordinaryCollection, location: .undetermined)
            currentWindow.close()
        }
        
        return (wc != nil)
    }
    
    /// Move the User's Collection to a new location
    func stashNotesInSubfolder(currentIO: NotenikIO, currentWindow: CollectionWindow) -> Bool {
        guard let io = currentIO as? FileIO else { return false }
        guard io.collectionOpen else { return false }
        guard let collection = io.collection else { return false }
        guard let url = collection.fullPathURL else { return false }
        let notesSubFolder = collection.lib.getResource(type: .notesSubfolder)
        if notesSubFolder.exists && notesSubFolder.isDirectory {
            if !notesSubFolder.isEmpty() {
                communicateError("Cannot stash - notes folder already exists and is not empty")
                return false
            }
        } else {
            let created = notesSubFolder.ensureExistence()
            guard created else { return false }
        }

        let relo = CollectionRelocation()
        let ok = relo.copyOrMoveCollection(from: collection.fullPath, to: notesSubFolder.actualPath, move: true)
        if !ok {
            communicateError("Could not stash notes in notes subfolder")
            return false
        }
        
        if let lib = collection.lib {
            lib.setPaths()
        }
        
        currentWindow.close()
        let wc = openFileWithNewWindow(fileURL: url, readOnly: false)
        if wc != nil {
            notenikFolderList.add(url: url, type: .webCollection, location: .undetermined)
        }
        
        return (wc != nil)
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
        let folderPath = folderURL.path
        let alreadyExists = FileManager.default.fileExists(atPath: folderPath)
        guard !alreadyExists else { return false }
        do {
            try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            communicateError("Attempt to create new directory failed")
            return false
        }
        return true
    }
    
    /// Create a new Collection set up to generate a companion website.
    func newWebsite(fileURL: URL) -> Bool {
        let webCollection = WebCollection(fileURL: fileURL)
        guard webCollection.initCollection() else { return false }
        
        notenikFolderList.add(url: webCollection.notesFolderURL, type: .ordinaryCollection, location: .undetermined)
        
        saveCollectionInfo(webCollection.io.collection!)

        let wc = assignIOtoWindow(io: webCollection.io)
        let ok = (wc != nil)
        
        return ok
    }
    
    /// Now that we have a disk location, let's take other steps
    /// to create a new collection.
    func newCollection(fileURL: URL) -> CollectionWindowController? {
        
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
        
        let initOK = io.initCollection(realm: realm, collectionPath: collectionURL.path, readOnly: false)
        guard initOK else { return nil }
        
        notenikFolderList.add(url: collectionURL, type: .ordinaryCollection, location: .undetermined)
        io.addDefaultDefinitions()
        
        // Now let the user tailor the starting Collection default values
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            if let collectionPrefsWindow = collectionPrefsController.window {
                let collectionPrefsVC = collectionPrefsWindow.contentViewController as! CollectionPrefsViewController
                let defsRemoved = DefsRemoved()
                collectionPrefsVC.passCollectionPrefsRequesterInfo(collection: io.collection!,
                                                                   window: collectionPrefsController,
                                                                   defsRemoved: defsRemoved)
                let returnCode = application.runModal(for: collectionPrefsWindow)
                if returnCode == NSApplication.ModalResponse.OK {
                    return collectionPrefsModified(collection: io.collection!)
                } else {
                    // ???
                }
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Couldn't get a Collection Prefs Window Controller!")
            return nil
        }
        
        return nil
    }
    
    
    /// Increase the font size used on the Edit panel
    func viewIncreaseEditFontSize() {
        appPrefsCocoa.increaseEditFontSize(by: 1.0)
        appPrefsCocoa.saveDefaults()
        adjustEditWindows()
    }
    
    /// Decrease the font size used on the Edit Panel
    func viewDecreaseEditFontSize() {
        appPrefsCocoa.decreaseEditFontSize(by: 1.0)
        appPrefsCocoa.saveDefaults()
        adjustEditWindows()
    }
    
    func viewResetEditFontSize() {
        appPrefsCocoa.resetEditFontSize()
        appPrefsCocoa.saveDefaults()
        adjustEditWindows()
    }
    
    /// Adjust all the open windows to reflect any changes in the UI appearance.
    func adjustEditWindows() {
        for window in windows {
            let editing = window.noteTabs!.tabView.selectedTabViewItem!.label == "Edit"
            guard let noteIO = window.io else { continue }
            var klassName: String?
            var note = window.editVC!.selectedNote
            if editing {
                let (outcome, modNote) = window.modIfChanged()
                if modNote != nil {
                    note = modNote
                }
                guard outcome != .tryAgain else { continue }
            }
            if note != nil && note!.hasKlass() {
                klassName = note!.klass.value
            }
            let holdPendingEdits = window.pendingEdits
            window.pendingEdits = false
            window.editVC!.containerViewBuilt = false
            window.editVC!.configureEditView(noteIO: noteIO, klassName: klassName)
            if note != nil {
                _ = window.viewCoordinator.focusOn(initViewID: "juggler",
                                                   note: note,
                                                   position: nil, row: -1, searchPhrase: nil)
                /* window.select(note: note,
                              position: nil,
                              source: .action,
                              andScroll: true,
                              searchPhrase: nil) */
                window.pendingEdits = holdPendingEdits
                if editing {
                    window.openEdits(self)
                }
            }
        }
    }
    
    func adjustListViews() {
        for window in windows {
            if let lvc = window.listVC {
                lvc.reload()
            }
        }
    }
    
    func displayRefresh() {
        for window in windows {
            window.reloadDisplayView(self)
        }
    }
    
    func showAppPreferences() {
        if let prefsController = self.prefsStoryboard.instantiateController(withIdentifier: "prefsWC") as? PrefsWindowController {
            prefsController.showWindow(self)
        } else {
            communicateError("Couldn't get a Prefs Window Controller!")
        }
    }
    
    /// Let the calling class know that the user has completed modifications
    /// of the Collection Preferences.
    ///
    /// - Parameters:
    ///   - ok: True if they clicked on OK, false if they clicked Cancel.
    ///   - collection: The Collection whose prefs are being modified.
    ///   - window: The Collection Prefs window.
    func collectionPrefsModified(collection: NoteCollection) -> CollectionWindowController? {
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        let ok = io.newCollection(collection: collection, withFirstNote: true)
        guard ok else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "CollectionJuggler",
                              level: .error,
                              message: "Problems initializing the new collection at " + collection.fullPath)
            return nil
        }
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionJuggler",
                          level: .info,
                          message: "New Collection successfully initialized at \(collection.fullPath)")
        
        saveCollectionInfo(collection)

        return assignIOtoWindow(io: io)
    }
    
    /// Make the given collection the easily accessible Essential collection
    ///
    /// - Parameter io: The Notenik Input/Output module accessing the collection that is to become essential
    func makeCollectionEssential(io: NotenikIO) {
        guard let collection = io.collection else { return }
        guard let collectionURL = collection.fullPathURL else { return }
        appPrefs.essentialURL = collectionURL
    }
    
    /// Open the Essential Collection, if we have one
    func openEssentialCollection() {
        guard let essentialURL = appPrefs.essentialURL else { return }
        notenikFolderList.add(url: essentialURL, type: .ordinaryCollection, location: .undetermined)
        _ = openFileWithNewWindow(fileURL: essentialURL, readOnly: false)
    }
    
    /// Open the Notenik Knowledge Base.
    func openKB() -> CollectionWindowController? {
        let path = notenikFolderList.kbNode.path
        let kbWindowNumbers = appPrefs.kbWindow
        let kbwc = openFileWithNewWindow(folderPath: path,
                                         readOnly: true,
                                         windowNumbers: kbWindowNumbers)
        if kbwc != nil {
            kbwc!.selectFirstNote()
        }
        return kbwc
    }
    
    func openMC() -> CollectionWindowController? {
        let path = notenikFolderList.mcNode.path
        let mcWindowNumbers = appPrefs.mcWindow
        let mcwc = openFileWithNewWindow(folderPath: path,
                                         readOnly: true,
                                         windowNumbers: mcWindowNumbers)
        if mcwc != nil {
            mcwc!.selectFirstNote()
        }
        return mcwc
    }
    
    func whatIsNew() {
        let path = notenikFolderList.kbNode.path
        let kbWindowNumbers = appPrefs.kbWindow
        guard let kbwc = openFileWithNewWindow(folderPath: path,
                                               readOnly: true,
                                               windowNumbers: kbWindowNumbers) else { return }
        guard let io = kbwc.io else { return }
        guard let note = io.getNote(forID: "versionhistory") else {
            communicateError("Knowledge Base Version History could not be found", alert: true)
            return
        }
        let position = io.positionOfNote(note)
        let (nextNote, nextPosition) = io.nextNote(position)
        _ = kbwc.viewCoordinator.focusOn(initViewID: "juggler",
                                         note: nextNote, position: nextPosition,
                                         row: -1, searchPhrase: nil)
        // kbwc.select(note: nextNote, position: nextPosition, source: .action, andScroll: true)
    }
    
    func mdCheatSheet() {
        let path = notenikFolderList.kbNode.path
        let kbWindowNumbers = appPrefs.kbWindow
        guard let kbwc = openFileWithNewWindow(folderPath: path,
                                               readOnly: true,
                                               windowNumbers: kbWindowNumbers) else { return }
        guard let io = kbwc.io else { return }
        guard let note = io.getNote(forID: "markdowncheatsheet") else {
            communicateError("Markdown Cheat Sheet could not be found", alert: true)
            return
        }
        let position = io.positionOfNote(note)
        _ = kbwc.viewCoordinator.focusOn(initViewID: "juggler",
                                         note: note, position: position,
                                         row: -1, searchPhrase: nil)
        // kbwc.select(note: note, position: position, source: .action, andScroll: true)
    }
    
    func openTips() -> CollectionWindowController? {
        let path = notenikFolderList.tipsNode.path
        let tipsWindowNumbers = appPrefs.tipsWindow
        let tipswc = openFileWithNewWindow(folderPath: path, readOnly: true, windowNumbers: tipsWindowNumbers)
        if tipswc != nil {
            tipswc!.selectFirstNote()
        }
        return tipswc
    }
    
    /// Let the user select a folder, so that Notenik can have unfettered
    /// access to everything within that folder.
    func grantFolderAccess(confirm: Bool = true) {
        let openPanel = NSOpenPanel();
        openPanel.title = "Grant Access to Entire Folder"
        // let parent = osdir.directoryURL
        let parent = URL(fileURLWithPath: "/Users/")
        // if parent != nil {
            openPanel.directoryURL = parent
        // }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.message = "Grant Notenik Access to the Selected Folder"
        openPanel.prompt = "Grant Access"
        let result = openPanel.runModal()
        if result == .OK && confirm {
            // docController!.noteNewRecentDocumentURL(openPanel.url!)
            accessGranted(accessFolder: openPanel.url)
        }
    }
    
    func accessGranted(accessFolder: URL?) {
        guard let url = accessFolder else { return }
        let dialog = NSAlert()
        dialog.alertStyle = .informational
        dialog.messageText = "Notenik Access Granted to \(url.path)"
        dialog.addButton(withTitle: "OK")
        let _ = dialog.runModal()
    }
    
    /// Respond to a user request to open another Collection. Present the user
    /// with an Open Panel to allow the selection of a folder containing an
    /// existing Notenik Collection. 
    func userRequestsOpenCollection(requestedParent: URL? = nil) {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Notenik Collection"
        if requestedParent != nil {
            openPanel.directoryURL = requestedParent!
        } else {
            let parent = osdir.directoryURL
            if parent != nil {
                openPanel.directoryURL = parent!
            }
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let result = openPanel.runModal()
        if result == .OK {
            MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            _ = self.openFileWithNewWindow(fileURL: openPanel.url!, readOnly: false)
        }
    }
    
    func openNoteFile(link: NotenikLink) -> Bool {
        guard let noteURL = link.url else { return false }
        let folderURL = noteURL.deletingLastPathComponent()
        let cwc = openFileWithNewWindow(fileURL: folderURL, readOnly: false)
        guard let controller = cwc else {
            communicateError("Unable to open desired Collection, possibley due to expired permissions", alert: true)
            return false
        }
        guard let io = controller.io else { return false }
        let fileName = noteURL.deletingPathExtension().lastPathComponent
        let noteID = StringUtils.toCommon(fileName)
        guard let note = io.getNote(forID: noteID) else {
            communicateError("Note could not be found with this ID: \(noteID)")
            return false
        }
        _ = controller.viewCoordinator.focusOn(initViewID: "juggler",
                                               note: note,
                                               position: nil, row: -1, searchPhrase: nil)
        // controller.select(note: note, position: nil, source: .action, andScroll: true)
        return true
    }
    
    /// Attempt to open a Notenik collection, starting with a file path.
    ///
    /// - Parameters:
    ///   - folderPath: The path to the collection folder.
    ///   - readOnly:   Should this collection be opened read-only?
    /// - Returns: True if open was successful; false otherwise.
    func openFileWithNewWindow(folderPath: String,
                               readOnly: Bool,
                               windowNumbers: String = "") -> CollectionWindowController? {
        let fileURL = URL(fileURLWithPath: folderPath)
        return openFileWithNewWindow(fileURL: fileURL,
                                     readOnly: readOnly,
                                     windowNumbers: windowNumbers)
    }
    
    /// Attempt to open a Notenik Collection.
    ///
    /// - Parameter fileURL: A URL pointing to a Notenik folder.
    /// - Returns: True if open was successful, false if not.
    func openFileWithNewWindow(fileURL: URL,
                               readOnly: Bool,
                               windowNumbers: String = "") -> CollectionWindowController? {
        
        var collectionURL: URL
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        // If the collection is already open, then simply bring
        // that window to the front.
        for window in windows {
            guard let windowCollection = window.io?.collection else { continue }
            guard let windowURL = windowCollection.fullPathURL else { continue }
            if folderURLsEqual(url1: windowURL, url2: collectionURL)
                && !windowCollection.isRealmCollection
                && window.window != nil {
                window.window!.makeKeyAndOrderFront(self)
                return window
            }
        }
        
        let (multiCollection, io) = multi.provision(fileURL: fileURL, inspector: nil, readOnly: readOnly)
        guard let collection = multiCollection else { return nil }
        saveCollectionInfo(collection)
        let wc = assignIOtoWindow(io: io)
        if wc != nil && !windowNumbers.isEmpty {
            wc!.setNumbers(windowNumbers)
        }
        notenikFolderList.add(collection)
        return wc
    }
    
    /// Assign an Input/Output module to a new or existing window.
    /// - Parameter io: An I/O module already opened with a Collection.
    func assignIOtoWindow(io: NotenikIO) -> CollectionWindowController? {
        var assignedController: CollectionWindowController?
        if initialWindowUsed {
            if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
                windowController.shouldCascadeWindows = true
                windowController.io = io
                self.registerWindow(window: windowController)
                windowController.showWindow(self)
                assignedController = windowController
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionJuggler",
                                  level: .error,
                                  message: "Couldn't get a Window Controller!")
            }
        } else {
            initialWindow!.io = io
            assignedController = initialWindow
            initialWindowUsed = true
        }
        return assignedController
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
    
    /// Take appropriate actions when a Collection window is closing.
    func windowClosing(wc: CollectionWindowController) {
        setLastSelection(title: "", link: "", filepath: "", wc: nil)
        var windowCount = 0
        for nextWC in windows {
            if nextWC.window == nil {
                // Don't count it
            } else {
                if nextWC as AnyObject === wc as AnyObject {
                    // This is the closing window -- don't count it
                } else if !nextWC.window!.isVisible {
                    // Don't count it if it is not visible
                } else if nextWC.io == nil {
                    // Don't count it if no i/o module
                } else if nextWC.io!.collectionOpen {
                    // Count it if collection is open
                    windowCount += 1
                }
            }
        }
        if windowCount == 0 {
            navBoard()
        }
    }
    
    /// Display the Navigation Board.
    func navBoard() {
        if navController != nil {
            navController!.reload()
            navController!.showWindow(self)
        } else if let navWC = self.navStoryboard.instantiateController(withIdentifier: "navigatorWC") as? NavigatorWindowController {
            navWC.juggler = self
            navWC.showWindow(self)
            navController = navWC
        } else {
            communicateError("Couldn't get a Navigation Window Controller!", alert: true)
        }
    }
    
    /// Display the Quick Action Storyboard.
    func quickAction() {
        if quickActionController != nil {
            quickActionController!.restart()
            quickActionController!.showWindow(self)
        } else if let quickWC = self.quickActionStoryBoard.instantiateController(withIdentifier: "quickWC") as? QuickActionWindowController {
            quickWC.juggler = self
            quickWC.showWindow(self)
            quickActionController = quickWC
        } else {
            communicateError("Couldn't get a Quick Action Window Controller", alert: true)
        }
    }
    
    /// Once we've opened a collection, save some info about it so we can use it later
    func saveCollectionInfo(_ collection: NoteCollection) {
        guard let collectionURL = collection.fullPathURL else { return }
        guard !collection.readOnly else { return }
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
        if let dirURL = AppPrefs.shared.scriptFolderURL {
            openPanel.directoryURL = dirURL
        } else {
            openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        let result = openPanel.runModal()
        if result == .OK {
            self.launchScript(fileURL: openPanel.url!)
        }
    }
    
    func scriptRerun() {
        guard lastScript != nil else {
            communicateError("Last Script to Rerun is not retained between launches", alert: true)
            return
        }
        ensureScriptController()
        guard scriptWindowController != nil else { return }
        scriptWindowController!.showWindow(self)
        scriptWindowController!.scriptOpenInput(lastScript!, goNow: true)
    }
    
    /// Launch a script to be played.
    func launchScript(fileURL: URL) {
        AppPrefs.shared.scriptFolderURL = fileURL.deletingLastPathComponent()
        ensureScriptController()
        guard scriptWindowController != nil else { return }
        scriptWindowController!.showWindow(self)
        lastScript = fileURL
        scriptWindowController!.scriptOpenInput(fileURL)
    }
    
    func showScriptWindow() {
        ensureScriptController()
        guard scriptWindowController != nil else { return }
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
    
    var lastWC: CollectionWindowController? {
        get {
            return _lastWC
        }
        set {
            _lastWC = newValue
            updateSortMenu()
            updateDisplayModeMenu()
            updateShowHideOutline()
        }
    }
    var _lastWC: CollectionWindowController? = nil
    
    func setLastSelection(title: String,
                          link: String,
                          filepath: String,
                          wc: CollectionWindowController?) {
        
        if wc == nil {
            lastSelectedNoteTitle = title
            lastSelectedNoteCustomURL = link
            lastSelectedNoteFilepath = filepath
            lastWC = wc
            return
        }
        guard let collection = wc?.io?.collection else { return }
        guard !collection.readOnly else { return }
        lastSelectedNoteTitle = title
        lastSelectedNoteCustomURL = link
        lastSelectedNoteFilepath = filepath
        lastWC = wc
    }
    
    func getLastSelectedNoteTitle() -> String {
        return lastSelectedNoteTitle
    }
    
    func getLastSelectedNoteCustomURL() -> String {
        return lastSelectedNoteCustomURL
    }
    
    func getLastSelectedNoteFilePath() -> String {
        return lastSelectedNoteFilepath
    }
    
    func getLastUsedWindowController() -> CollectionWindowController? {
        return lastWC
    }
    
    func updateSortMenu() {
        guard sortMenu != nil else { return }
        var reverseMenuItem: NSMenuItem?
        var blankDatesLastItem: NSMenuItem?
        var menuIx = 0
        let reverseIx = sortMenu!.items.count - 2
        let blankDatesLastIx = sortMenu!.items.count - 1
        for menuItem in sortMenu!.items {
            menuItem.state = .off
            if menuIx == reverseIx {
                reverseMenuItem = menuItem
            } else if menuIx == blankDatesLastIx {
                blankDatesLastItem = menuItem
            }
            menuIx += 1
        }
        guard let collection = _lastWC?.io?.collection else { return }
        switch collection.sortParm {
        case .title:
            sortMenu!.items[0].state = .on
        case .seqPlusTitle:
            sortMenu!.items[1].state = .on
        case .tasksByDate:
            sortMenu!.items[2].state = .on
        case .tasksBySeq:
            sortMenu!.items[3].state = .on
        case .author:
            sortMenu!.items[6].state = .on
        case .tagsPlusTitle:
            sortMenu!.items[4].state = .on
        case .tagsPlusSeq:
            sortMenu!.items[5].state = .on
        case .custom:
            break
        case .dateAdded:
            sortMenu!.items[7].state = .on
        case .dateModified:
            sortMenu!.items[8].state = .on
        case .datePlusSeq:
            sortMenu!.items[9].state = .on
        case .rankSeqTitle:
            sortMenu!.items[10].state = .on
        case .klassTitle:
            sortMenu!.items[11].state = .on
        case .klassDateTitle:
            sortMenu!.items[12].state = .on
        case .folderTitle:
            sortMenu!.items[13].state = .on
        case .folderDateTitle:
            sortMenu!.items[14].state = .on
        case .folderSeqTitle:
            sortMenu!.items[15].state = .on
        case .lastNameFirst:
            sortMenu!.items[16].state = .on
        }
        if collection.sortDescending && reverseMenuItem != nil {
            reverseMenuItem!.state = .on
        }
        if collection.sortBlankDatesLast && blankDatesLastItem != nil {
            blankDatesLastItem!.state = .on
        }
    }
    
    func updateDisplayModeMenu() {
        guard displayModeMenu != nil else { return }
        var menuIx = 0
        for menuItem in displayModeMenu!.items {
            menuItem.state = .off
            menuIx += 1
        }
        guard let collection = _lastWC?.io?.collection else { return }
        switch collection.displayMode {
        case .normal:
            displayModeMenu!.items[0].state = .on
        case .streamlinedReading:
            displayModeMenu!.items[1].state = .on
        case .presentation:
            displayModeMenu!.items[2].state = .on
        case .quotations:
            displayModeMenu!.items[3].state = .on
        case .custom:
            displayModeMenu!.items[4].state = .on
        }
    }
    
    func updateShowHideOutline() {
        guard let collection = _lastWC?.io?.collection else { return }
        if collection.seqFieldDef == nil {
            showHideOutline.isEnabled = false
            showHideOutline.title = "Show/Hide Outline Tab"
            collection.outlineTab = false
        } else {
            showHideOutline.isEnabled = true
            if collection.outlineTab {
                showHideOutline.title = "Hide Outline Tab"
            } else {
                showHideOutline.title = "Show Outline Tab"
            }
        }
    }
    
    let countsStoryboard:          NSStoryboard = NSStoryboard(name: "Counts", bundle: nil)
    var countsWC:                  CountsWindowController?
    var countsVC:                  CountsViewController?
    
    /// Show the user a window displaying various counts for the body of the current Note.
    func showCounts(_ sender: Any) -> CountsViewController? {
        guard appPrefs.notenikParser else {
            communicateError("You must select the Notenik Parser in the Application Preferences in order to show the Counts window", alert: true)
            return nil
        }
        if countsWC == nil {
            if let countsWindowController = self.countsStoryboard.instantiateController(withIdentifier: "countsWC") as? CountsWindowController {
                guard let countsViewController = countsWindowController.contentViewController as? CountsViewController else { return nil }
                countsWC = countsWindowController
                countsVC = countsViewController
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Couldn't get a Counts Window Controller!")
            }
        }
        if countsWC != nil {
            countsWC!.showWindow(sender)
        }
        return countsVC
    }
    
    func folderURLsEqual(url1: URL, url2: URL) -> Bool {
        return folderPathWithoutSlash(url: url1) == folderPathWithoutSlash(url: url2)
    }
    
    func folderPathWithoutSlash(url: URL) -> String {
        var path = url.absoluteString
        if path.hasSuffix("/") {
            path.removeLast()
        }
        return path
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

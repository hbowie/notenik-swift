//
//  CollectionController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

/// A singleton object that controls all of the Note Collections that are open. 
class CollectionJuggler: NSObject {
    
    static let shared = CollectionJuggler()
    
    let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    let defaults = UserDefaults.standard
    let parentFolderKey = "parent-folder"
    var windows: Array<CollectionWindowController> = Array()
    var highestWindowNumber = -1
    
    override private init() {
        super.init()
    }
    
    func startup() {

    }
    
    /// Respond to a user request to open another Collection. Present the user
    /// with an Open Panel to allow the selection of a folder containing a
    /// existing Notenik Collection. 
    func userRequestsOpenCollection() {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Notenik Collection"
        var parent = self.defaults.url(forKey: self.parentFolderKey)
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
                let io: NotenikIO = FileIO()
                let realm = io.getDefaultRealm()
                realm.path = ""
                let selectedURL = openPanel.url
                var collectionURL: URL
                if FileUtils.isDir(selectedURL!.path) {
                    collectionURL = selectedURL!
                } else {
                    collectionURL = selectedURL!.deletingLastPathComponent()
                }
                let collection = io.openCollection(realm: realm, collectionPath: collectionURL.path)
                if collection == nil {
                    Logger.shared.log(skip: true, indent: 0, level: LogLevel.moderate,
                                      message: "Problems opening the collection at " + collectionURL.path)
                } else {
                    Logger.shared.log(skip: true, indent: 0, level: LogLevel.normal,
                                      message: "Collection successfully opened: \(collection!.title)")
                    parent = collectionURL.deletingLastPathComponent()
                    self.defaults.set(parent, forKey: self.parentFolderKey)
                    if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
                        windowController.shouldCascadeWindows = true
                        windowController.io = io
                        self.registerWindow(window: windowController)
                        windowController.showWindow(self)
                    } else {
                        Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                                          message: "Couldn't get a Window Controller!")
                    }
                }
            }
        }
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
            loadInitialCollection(window: window)
        }
    }
    
    /// Find a collection to show in the initial window shown upon application launch.
    ///
    /// - Parameter window: <#window description#>
    func loadInitialCollection(window: CollectionWindowController) {
        
        // For now, let's just show the Notenik Help Notes
        var io: NotenikIO = FileIO()
        let provider = io.getProvider()
        let realm = Realm(provider: provider)
        realm.name = "Herb Bowie"
        realm.path = ""
        let path = Bundle.main.resourcePath! + "/notenik-swift-intro"
        _ = io.openCollection(realm: realm, collectionPath: path)
        
        // For now, let's sort everything by title
        io.sortParm = .title
        
        window.io = io
    }

}
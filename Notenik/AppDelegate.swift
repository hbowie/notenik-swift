//
//  AppDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let juggler : CollectionJuggler = CollectionJuggler.shared
    var docController: NoteDocumentController!
    var recentDocumentURLs: [URL] = []
    
    let prefsStoryboard: NSStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
    let logStoryboard:   NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    
    var logController: LogWindowController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        docController = NoteDocumentController()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        juggler.docController = docController
        recentDocumentURLs = docController.recentDocumentURLs
        let maxRecent = docController.maximumRecentDocumentCount
        juggler.startup()
    }
    
    @IBAction func menuAppPreferences(_ sender: NSMenuItem) {
        if let prefsController = self.prefsStoryboard.instantiateController(withIdentifier: "prefsWC") as? PrefsWindowController {
            prefsController.showWindow(self)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Prefs Window Controller!")
        }
    }
    
    @IBAction func menuFileNewAction(_ sender: NSMenuItem) {
        juggler.userRequestsNewCollection()
    }

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        juggler.userRequestsOpenCollection()
    }
    
    @IBAction func menuFileOpenEssential(_ sender: NSMenuItem) {
        juggler.openEssentialCollection()
    }
    
    @IBAction func menuFileCreateMasterCollection(_ sender: Any) {
        juggler.userRequestsCreateMasterCollection()
    }
    
    @IBAction func menuFileOpenMasterCollection(_ sender: Any) {
        juggler.userRequestsOpenMasterCollection()
    }
    
    @IBAction func menuFileSearchForCollections( _ sender: Any) {
        let master = MasterCollection.shared
        if master.masterIO != nil && master.masterIO!.collectionOpen {
            juggler.searchForCollections()
        }
    }
    
    @IBAction func menuOpenHelpNotes(_ sender: NSMenuItem) {
        juggler.openHelpNotes()
    }
    
    @IBAction func menuWindowLog(_ sender: NSMenuItem) {
        if let logController = self.logStoryboard.instantiateController(withIdentifier: "logWC") as? LogWindowController {
            logController.showWindow(self)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Log Window Controller!")
        }
    }
    
    @IBAction func menuHelpNotenikDotNet(_ sender: NSMenuItem) {
        let url = URL(string: "https://notenik.net")
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func menuHelpPowerSurgePubDotCom(_ sender: NSMenuItem) {
        let url = URL(string: "https://powersurgepub.com")
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    /// Attempt to open the passed file
    func application(_ sender: NSApplication,
                     openFile filename: String) -> Bool {
        juggler.openFileWithNewWindow(folderPath: filename, readOnly: false)
        return true
    }
    
}


//
//  AppDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NoteDisplayMaster {
    
    let fm      = FileManager.default

    @IBOutlet weak var favsToHTML: NSMenuItem!
    @IBOutlet weak var iCloudMenu: NSMenu!
    
    var appPrefs:     AppPrefs!
    var displayPrefs: DisplayPrefs!
    var juggler: CollectionJuggler!
    let logger = Logger.shared
    var stage = "0"
    var launchURLs: [URL] = []
    
    var notenikFolderList: NotenikFolderList!
    
    var docController: NoteDocumentController!
    var recentDocumentURLs: [URL] = []
    
    let prefsStoryboard:            NSStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
    let displayPrefsStoryboard:     NSStoryboard = NSStoryboard(name: "DisplayPrefs", bundle: nil)
    let logStoryboard:              NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    
    var logController: LogWindowController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        docController = NoteDocumentController()
        stage = "1"
        
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        appPrefs = AppPrefs.shared
        displayPrefs = DisplayPrefs.shared
        displayPrefs.setMaster(master: self)
        juggler = CollectionJuggler.shared
        juggler.docController = docController
        recentDocumentURLs = docController.recentDocumentURLs
        stage = "2"
        logger.logDestPrint = false
        logger.logDestUnified = true
        juggler.startup()
        juggler.makeRecentDocsKnown(recentDocumentURLs)
        
        // Let's build a submenu showing all folders in the iCloud Notenik folder.
        iCloudMenu.removeAllItems()
        notenikFolderList = NotenikFolderList.shared
        for folder in notenikFolderList {
            if folder.location == .iCloudContainer {
                let item = NSMenuItem(title: folder.folderName, action: #selector(openICloudItem(_:)), keyEquivalent: "")
                iCloudMenu.addItem(item)
            }
        }
        
        var successfulOpens = 0
        if launchURLs.count > 0 {
            successfulOpens = juggler.open(urls: launchURLs)
        }
        if successfulOpens == 0 {
            juggler.loadInitialCollection()
        }
        if !AppPrefs.shared.americanEnglish {
            favsToHTML.title = "Favourites to HTML..."
        }
        
        // Done launching
        appPrefs.appLaunching = false
    }
    
    /// Open an iCloud item that's been selected by the user from the submenu created above.
    @objc func openICloudItem(_ sender: NSMenuItem) {
        let urlToOpen = notenikFolderList.getICloudURLFromFolderName(sender.title)
        if urlToOpen != nil {
            _ = juggler.open(urls: [urlToOpen!])
        }
    }
    
    /// Standard open when passed a list of URLs. 
    func application(_ application: NSApplication, open urls: [URL]) {
        if stage == "1" {
            launchURLs = urls
        } else {
            _ = juggler.open(urls: urls)
        }
    }
    
    @IBAction func menuAppPreferences(_ sender: NSMenuItem) {
        if let prefsController = self.prefsStoryboard.instantiateController(withIdentifier: "prefsWC") as? PrefsWindowController {
            prefsController.showWindow(self)
        } else {
            logger.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "AppDelegate",
                              level: .error,
                              message: "Couldn't get a Prefs Window Controller!")
        }
    }
    
    @IBAction func navBoard(_ sender: NSMenuItem) {
        juggler.navBoard()
    }
    
    @IBAction func menuFileNewAction(_ sender: NSMenuItem) {
        juggler.userRequestsNewCollection()
    }
    
    @IBAction func menuFileNewWebsiteAction(_ sender: NSMenuItem) {
        juggler.userRequestsNewWebsite()
    }

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        juggler.userRequestsOpenCollection()
    }
    
    @IBAction func menuFileOpenEssential(_ sender: NSMenuItem) {
        juggler.openEssentialCollection()
    }
    
    @IBAction func menuFileOpenParentRealm(_ sender: Any) {
        _ = juggler.openParentRealm()
    }
    
    @IBAction func scriptPlay(_ sender: Any) {
        juggler.scriptOpen()
    }
    
    @IBAction func viewIncreaseEditFontSize(_ sender: Any) {
        juggler.viewIncreaseEditFontSize()
    }
    
    @IBAction func viewDecreaseEditFontSize(_ sender: Any) {
        juggler.viewDecreaseEditFontSize()
    }
    
    @IBAction func viewResetEditFontSize(_ sender: Any) {
        juggler.viewResetEditFontSize()
    }
    
    @IBAction func menuOpenHelpNotes(_ sender: NSMenuItem) {
        juggler.openHelpNotes()
    }
    
    @IBAction func menuWindowLog(_ sender: NSMenuItem) {
        if let logController = self.logStoryboard.instantiateController(withIdentifier: "logWC") as? LogWindowController {
            logController.showWindow(self)
        } else {
            logger.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "AppDelegate",
                              level: .fault,
                              message: "Couldn't get a Log Window Controller!")
        }
    }
    
    @IBAction func menuWindowScripter(_ sender: Any) {
        juggler.showScriptWindow()
    }
    
    @IBAction func menuHelpNotenikDotNet(_ sender: NSMenuItem) {
        let url = URL(string: "https://notenik.net")
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func menuHelpRateOnAppStore(_ sender: NSMenuItem) {
        let url = URL(string: "https://itunes.apple.com/app/id1465997984?action=write-review")
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func displayPrefs(_ sender: Any) {
        if let displayPrefsController = self.displayPrefsStoryboard.instantiateController(withIdentifier: "displayPrefsWC") as? DisplayPrefsWindowController {
            displayPrefsController.showWindow(self)
            // displayPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io!.collection!)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Display Prefs Window Controller!")
        }
    }
    
    func displayRefresh() {
        juggler.displayRefresh()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    /// Log an information message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppDelegate",
                          level: .error,
                          message: msg)
    }
    
}


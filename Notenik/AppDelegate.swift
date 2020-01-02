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

    @IBOutlet weak var favsToHTML: NSMenuItem!
    
    let juggler: CollectionJuggler = CollectionJuggler.shared
    let logger = Logger.shared
    var stage = "0"
    var launchURLs: [URL] = []
    
    var docController: NoteDocumentController!
    var recentDocumentURLs: [URL] = []
    
    let prefsStoryboard: NSStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
    let logStoryboard:   NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    
    var logController: LogWindowController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        docController = NoteDocumentController()
        stage = "1"
        
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let appPrefs = AppPrefs.shared
        juggler.docController = docController
        recentDocumentURLs = docController.recentDocumentURLs
        stage = "2"
        logger.logDestPrint = false
        logger.logDestUnified = true
        juggler.startup()
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
    
    @IBAction func menuFileNewAction(_ sender: NSMenuItem) {
        juggler.userRequestsNewCollection()
    }

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        juggler.userRequestsOpenCollection()
    }
    
    @IBAction func menuFileOpenEssential(_ sender: NSMenuItem) {
        juggler.openEssentialCollection()
    }
    
    @IBAction func menuFileOpenParentRealm(_ sender: Any) {
        juggler.openParentRealm()
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
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}


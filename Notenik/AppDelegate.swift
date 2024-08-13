//
//  AppDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import Intents

import NotenikUtils
import NotenikLib

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NoteDisplayMaster {
        
    let fm      = FileManager.default

    @IBOutlet weak var favsToHTML: NSMenuItem!
    @IBOutlet weak var iCloudMenu: NSMenu!

    @IBOutlet weak var sortMenu: NSMenu!
    @IBOutlet weak var displayModeMenu: NSMenu!
    
    @IBOutlet weak var navFindItem: NSMenuItem!
    @IBOutlet weak var navAdvSearchItem: NSMenuItem!
    @IBOutlet weak var navFindAgainItem: NSMenuItem!
    
    @IBOutlet weak var showHideOutline: NSMenuItem!
    
    var appPrefs:     AppPrefs?
    var displayPrefs: DisplayPrefs?
    var juggler: CollectionJuggler?
    let logger = Logger.shared
    var stage = "0"
    var launchURLs: [URL] = []
    
    var notenikFolderList: NotenikFolderList?
    
    var docController: NoteDocumentController?
    var recentDocumentURLs: [URL] = []
    
    let newControllerStoryboard:    NSStoryboard = NSStoryboard(name: "NewCollection", bundle: nil)
    let newInIcloudStoryboard:      NSStoryboard = NSStoryboard(name: "NewICloud", bundle: nil)
    let displayPrefsStoryboard:     NSStoryboard = NSStoryboard(name: "DisplayPrefs", bundle: nil)
    let editPrefsStoryboard:        NSStoryboard = NSStoryboard(name: "EditPrefs", bundle: nil)
    let logStoryboard:              NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    let newsStoryboard:             NSStoryboard = NSStoryboard(name: "News", bundle: nil)
    
    let expStoryboard:              NSStoryboard = NSStoryboard(name: "ViewExperiment", bundle: nil)
    
    var logController: LogWindowController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        docController = NoteDocumentController()
        stage = "1"
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        appPrefs = AppPrefs.shared
        
        if #available(macOS 10.14, *) {
            let appearance = appPrefs!.appAppearance
            switch appearance {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:
                break
            }
        }
        
        displayPrefs = DisplayPrefs.shared
        displayPrefs!.setMaster(master: self)
        juggler = CollectionJuggler.shared
        juggler!.docController = docController
        juggler!.sortMenu = sortMenu
        juggler!.displayModeMenu = displayModeMenu
        juggler?.showHideOutline = showHideOutline
        recentDocumentURLs = docController!.recentDocumentURLs
        stage = "2"
        logger.logDestPrint = false
        logger.logDestUnified = true
        juggler!.startup()
        juggler!.makeRecentDocsKnown(recentDocumentURLs)
        
        // Let's build a submenu showing all folders in the iCloud Notenik folder.
        iCloudMenu!.removeAllItems()
        notenikFolderList = NotenikFolderList.shared
        for folder in notenikFolderList! {
            if folder.location == .iCloudContainer {
                let item = NSMenuItem(title: folder.fileOrFolderName, action: #selector(openICloudItem(_:)), keyEquivalent: "")
                iCloudMenu!.addItem(item)
            }
        }
        
        var successfulOpens = 0
        if launchURLs.count > 0 {
            successfulOpens = juggler!.open(urls: launchURLs)
        }
        if successfulOpens == 0 {
            juggler!.loadInitialCollection()
        }
        if !AppPrefs.shared.americanEnglish {
            favsToHTML!.title = "Favourites to HTML..."
        }
        
        // Register our app to handle Apple events.
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleAppleEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        // Show Tips if requested
        if appPrefs!.tipsAtStartup {
            _ = juggler!.openTips()
        }
        
        // Done launching
        appPrefs!.appLaunching = false
        
        juggler!.checkGrantAndLoadShortcuts()
        
    }
    
    /// Open an iCloud item that's been selected by the user from the submenu created above.
    @objc func openICloudItem(_ sender: NSMenuItem) {
        let urlToOpen = notenikFolderList!.getICloudURLFromFolderName(sender.title)
        if urlToOpen != nil {
            _ = juggler!.open(urls: [urlToOpen!])
        }
    }
    
    /// Standard open when passed a list of URLs. 
    func application(_ application: NSApplication, open urls: [URL]) {
        if stage == "1" {
            launchURLs = urls
        } else {
            _ = juggler!.open(urls: urls)
        }
    }
    
    /// To handle events from Notenik's URL scheme.
    @objc func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        logInfo("Received an Apple Event")
        guard let appleEventDescription = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            logError("Could not get Apple Event Description")
            return
        }

        guard let appleEventURLString = appleEventDescription.stringValue else {
            logError("Could not get Apple Event URL String")
            return
        }
        
        guard let appleEventURL = URL(string: appleEventURLString) else {
            logError("Could not make a valid URL from: \(appleEventURLString)")
            return
        }

        logInfo("Apple Event passed URL: \(appleEventURL)")
        
        _ = juggler!.open(url: appleEventURL)
        
    }
    
    @IBAction func menuAppPreferences(_ sender: NSMenuItem) {
        juggler!.showAppPreferences()
    }
    
    @IBAction func mastProfile(_ sender: NSMenuItem) {
        let handle = appPrefs!.mastodonHandle
        let domain = appPrefs!.mastodonDomain
        var urlStr = ""
        guard !handle.isEmpty && !domain.isEmpty else {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = "You must first enter your Mastodon handle and domain in the Notenik General Settings"
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
            return
        }
        urlStr = "https://\(domain)/@\(handle)"
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func grantFolderAccess(_ sender: NSMenuItem) {
        juggler!.grantFolderAccess()
    }
    
    @IBAction func navBoard(_ sender: NSMenuItem) {
        juggler!.navBoard()
    }
    
    @IBAction func quickAction(_ sender: NSMenuItem) {
        juggler!.quickAction()
    }
    
    @IBAction func forgetShortcuts(_ sender: NSMenuItem) {
        notenikFolderList!.forgetShortcuts()
    }
    
    @IBAction func newCollection(_ sender: NSMenuItem) {
        if let newCollectionController = self.newControllerStoryboard.instantiateController(withIdentifier: "filenewWC") as? NewCollectionWindowController {
            newCollectionController.showWindow(self)
        } else {
            logError("Couldn't get a New Collection Window Controller")
        }
    }
    
    @IBAction func menuFileNewAction(_ sender: NSMenuItem) {
        juggler!.userRequestsNewCollection()
    }
    
    @IBAction func newInICloud(_ sender: Any) {
        if let newController = self.newInIcloudStoryboard.instantiateController(withIdentifier: "newcloudWC") as? NewICloudWindowController {
            newController.showWindow(self)
        } else {
            logger.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "AppDelegate",
                              level: .fault,
                              message: "Couldn't get a New in iCloud Window Controller!")
        }
    }
    
    @IBAction func menuFileNewWebsiteAction(_ sender: NSMenuItem) {
        juggler!.userRequestsNewWebsite()
    }

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        juggler!.userRequestsOpenCollection()
    }
    
    @IBAction func menuFileOpenEssential(_ sender: NSMenuItem) {
        juggler!.openEssentialCollection()
    }
    
    @IBAction func menuFileOpenParentRealm(_ sender: Any) {
        _ = juggler!.openParentRealm()
    }
    
    @IBAction func scriptPlay(_ sender: Any) {
        juggler!.scriptOpen()
    }
    
    @IBAction func scriptRerun(_ sender: Any) {
        juggler!.scriptRerun()
    }
    
    @IBAction func viewIncreaseEditFontSize(_ sender: Any) {
        juggler!.viewIncreaseEditFontSize()
    }
    
    @IBAction func viewDecreaseEditFontSize(_ sender: Any) {
        juggler!.viewDecreaseEditFontSize()
    }
    
    @IBAction func viewResetEditFontSize(_ sender: Any) {
        juggler!.viewResetEditFontSize()
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
        juggler!.showScriptWindow()
    }
    
    @IBAction func menuWindowExperiment(_ sender: Any) {
        if let expController = self.expStoryboard.instantiateController(withIdentifier: "viewExpWC") as? ViewExpWindowController {
            expController.showWindow(self)
        } else {
            logger.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "AppDelegate",
                              level: .fault,
                              message: "Couldn't get a View Experiment Window Controller!")
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Help Menu Items
    //
    // -----------------------------------------------------------
    
    @IBAction func menuOpenKB(_ sender: Any) {
        _ = juggler!.openKB()
    }
    
    @IBAction func menuOpenMC(_ sender: Any) {
        _ = juggler!.openMC()
    }
    
    @IBAction func menuWhatIsNew(_ sender: Any) {
        juggler!.whatIsNew()
    }
    
    @IBAction func menuCheatSheet(_ sender: Any) {
        juggler!.mdCheatSheet()
    }
    
    @IBAction func menuOpenTips(_ sender: Any) {
        _ = juggler!.openTips()
    }
    
    @IBAction func menuHelpNotenikDotNet(_ sender: NSMenuItem) {
        let url = URL(string: NotenikConstants.webNotenik)
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func donateViaKofi(_ sender: Any) {
        let url = URL(string: NotenikConstants.webDonate)
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func menuHelpDiscussionForum(_ sender: NSMenuItem) {
        guard let url = URL(string: NotenikConstants.webForum) else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func menuHelpNotenikIntro(_ sender: NSMenuItem) {
        if let url = URL(string: NotenikConstants.webIntro) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func menuHelpNotenikVideo(_ sender: NSMenuItem) {
        if let url = URL(string: NotenikConstants.webVid101) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func menuHelpRateOnAppStore(_ sender: NSMenuItem) {
        let url = URL(string: NotenikConstants.webMacAppStoreRate)
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
        juggler!.displayRefresh()
        juggler!.adjustListViews()
    }
    
    @IBAction func editPrefs(_ sender: Any) {
        if let editPrefsController = self.editPrefsStoryboard.instantiateController(withIdentifier: "editPrefsWC") as? EditPrefsWindowController {
            editPrefsController.showWindow(self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get an Edit Prefs Window Controller!")
        }
    }
    
    @available(macOS 11.0, *)
    func application(_ application: NSApplication, handlerFor intent: INIntent) -> Any? {
        if intent is GetNoteTitleIntent {
            return GetNoteTitleIntentHandler()
        } else if intent is GetNoteSharingLinkIntent {
            return GetNoteSharingLinkIntentHandler()
        } else if intent is GetNoteFilePathIntent {
            return GetNoteFilePathIntentHandler()
        } else if intent is AddNoteFromTextIntent {
            return AddNoteFromTextIntentHandler()
        } else if intent is RunScriptIntent {
            return RunScriptIntentHandler()
        } else if intent is OpenQuickActionIntent {
            return OpenQuickActionIntentHandler()
        }
        return nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let folders = notenikFolderList {
            folders.savePrefs()
        }
        
        // Stop handling Apple Events
        NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }
    
    /// Log an informative message.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppDelegate",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "AppDelegate",
                          level: .error,
                          message: msg)
    }
    
}


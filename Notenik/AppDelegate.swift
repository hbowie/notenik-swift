//
//  AppDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let juggler : CollectionJuggler = CollectionJuggler.shared
    var docController: NoteDocumentController!
    
    let prefsStoryboard: NSStoryboard = NSStoryboard(name: "Preferences", bundle: nil)
    let logStoryboard:   NSStoryboard = NSStoryboard(name: "Log", bundle: nil)
    
    var logController: LogWindowController?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        docController = NoteDocumentController()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        juggler.docController = docController
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

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        juggler.userRequestsOpenCollection()
    }
    
    @IBAction func menuFileOpenEssential(_ sender: NSMenuItem) {
        juggler.openEssentialCollection()
    }
    
    @IBAction func menuWindowLog(_ sender: NSMenuItem) {
        if let logController = self.logStoryboard.instantiateController(withIdentifier: "logWC") as? LogWindowController {
            print ("Found a good Log Controller")
            logController.showWindow(self)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Log Window Controller!")
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
        juggler.openFile(filename: filename)
        return true
    }
    
}


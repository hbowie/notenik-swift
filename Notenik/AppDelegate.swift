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

    let controller : CollectionController = CollectionController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        controller.startup()
    }

    @IBAction func menuFileOpenAction(_ sender: NSMenuItem) {
        
        controller.userRequestsOpenCollection()


    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


    
}


//
//  CollectionController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class CollectionController: NSObject {
    
    let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
    let defaults = UserDefaults.standard
    var windows: Array<CollectionWindowController> = Array()
    
    func startup() {
        let launchAtStartupValue = defaults.string(forKey: "launch-at-startup")
        if launchAtStartupValue == nil {
            print ("No launch at startup value found!")
        } else {
            print("Launch at startup value = \(launchAtStartupValue!)")
        }
    }
    
    func userRequestsOpenCollection() {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a Notenik Collection"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                print ("File Open Panel OK!")
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
                    print ("Problems opening the collection!")
                } else {
                    print ("Collection successfully opened: \(collection!.title)")
                    if let windowController = self.storyboard.instantiateController(withIdentifier: "collWC") as? CollectionWindowController {
                        windowController.io = io
                        self.windows.append(windowController)
                        windowController.showWindow(self)
                    } else {
                        print ("Couldn't get a Window Controller!")
                    }
                }
            }
        }
    }

}

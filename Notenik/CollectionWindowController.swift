//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class CollectionWindowController: NSWindowController {
    
    let juggler : CollectionJuggler = CollectionJuggler.shared
    var notenikIO: NotenikIO?
    var windowNumber = 0
    var splitViewController: NSSplitViewController?
    
        var collectionItem: NSSplitViewItem?
            var collectionTabs: NSTabViewController?
                var listItem: NSTabViewItem?
                    var listVC: NoteListViewController?
                var tagsItem: NSTabViewItem?
                    var tagsVC: NoteTagsViewController?

        var noteItem: NSSplitViewItem?
            var noteTabs: NSTabViewController?
                var displayItem: NSTabViewItem?
                    var displayVC: NoteDisplayViewController?
                var editItem: NSTabViewItem?
                    var editVC: NoteEditViewController?
    
    var io: NotenikIO? {
        get {
            return notenikIO
        }
        set {
            notenikIO = newValue
            guard notenikIO != nil && notenikIO!.collection != nil else {
                window!.title = "No Collection to Display"
                return
            }
            if notenikIO!.collection!.title == "" {
                window!.title = notenikIO!.collection!.path
            } else {
                window!.title = notenikIO!.collection!.title
            }
            if listVC == nil {
                Logger.shared.log(skip: false, indent: 0, level: LogLevel.severe,
                                  message: "NoteListViewController is nil!")
            } else {
                listVC!.io = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        getWindowComponents()
        juggler.registerWindow(window: self)
    }
    
    /// Let's grab the key components of the window and store them for easier access later
    func getWindowComponents() {
        if contentViewController != nil && contentViewController is NSSplitViewController {
            splitViewController = contentViewController as? NSSplitViewController
        }
        if splitViewController != nil {
            collectionItem = splitViewController!.splitViewItems[0]
            noteItem = splitViewController!.splitViewItems[1]
            collectionTabs = collectionItem?.viewController as? NSTabViewController
            collectionTabs?.selectedTabViewItemIndex = 0
            noteTabs = noteItem?.viewController as? NSTabViewController
            noteTabs?.selectedTabViewItemIndex = 0
            listItem = collectionTabs?.tabViewItems[0]
            listVC = listItem?.viewController as? NoteListViewController
            listVC!.window = self
            tagsItem = collectionTabs?.tabViewItems[1]
            tagsVC = tagsItem?.viewController as? NoteTagsViewController
            displayItem = noteTabs?.tabViewItems[0]
            displayVC = displayItem?.viewController as? NoteDisplayViewController
            editItem = noteTabs?.tabViewItems[1]
            editVC = editItem?.viewController as? NoteEditViewController
        }
    }
    
    func select(note: Note) {
        if displayVC != nil {
            displayVC!.select(note: note)
        }
    }

}

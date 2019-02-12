//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class CollectionWindowController: NSWindowController {
    
    @IBOutlet var shareButton: NSButton!
    
    let juggler:             CollectionJuggler = CollectionJuggler.shared
    var notenikIO:           NotenikIO?
    var windowNumber         = 0
    var splitViewController: NoteSplitViewController?
    
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
            
            if tagsVC == nil {
                Logger.shared.log(skip: false, indent: 0, level: LogLevel.severe,
                                  message:"NoteTagsView Controller is nil!")
            } else {
                tagsVC!.io = newValue
            }
            let (selected, position) = notenikIO!.firstNote()
            select(note: selected, position: position, source: .nav)
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        shareButton.sendAction(on: .leftMouseDown)
        getWindowComponents()
        juggler.registerWindow(window: self)
    }
    
    /// Let's grab the key components of the window and store them for easier access later
    func getWindowComponents() {
        if contentViewController != nil && contentViewController is NoteSplitViewController {
            splitViewController = contentViewController as? NoteSplitViewController
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
            tagsVC!.window = self
            displayItem = noteTabs?.tabViewItems[0]
            displayVC = displayItem?.viewController as? NoteDisplayViewController
            editItem = noteTabs?.tabViewItems[1]
            editVC = editItem?.viewController as? NoteEditViewController
        }
    }
    
    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        
        guard let noteIO = notenikIO else { return }
        
        switch sender.selectedSegment {
        case 0:
            // Go to top of list
            let (note, position) = noteIO.firstNote()
            select(note: note, position: position, source: .nav)
        case 1:
            let startingPosition = noteIO.position
            let (note, position) = noteIO.priorNote(startingPosition!)
            select(note: note, position: position, source: .nav)
        case 2:
            let startingPosition = noteIO.position
            let (note, position) = noteIO.nextNote(startingPosition!)
            select(note: note, position: position, source: .nav)
        default:
            let startingPosition = noteIO.position
        }
    }
    
    /// React to the selection of a note, coordinating the various views as needed.
    ///
    /// - Parameters:
    ///   - note:     A note, if we know which one has been selected.
    ///   - position: A position in the collection, if we know what it is.
    ///   - source:   An indicator of the source of the selection; if one of the views
    ///               being coordinated is the source, then we don't need to modify it.
    func select(note: Note?, position: NotePosition?, source: NoteSelectionSource) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        
        var noteToUse: Note? = note
        var positionToUse: NotePosition? = position
        
        if note != nil && (position == nil || position!.invalid) {
            positionToUse = notenikIO!.positionOfNote(note!)
        }
        
        if note == nil && position != nil && position!.valid {
            noteToUse = notenikIO!.getNote(at: position!.index)
        }
        
        if displayVC != nil  && noteToUse != nil {
            displayVC!.select(note: noteToUse!)
        }
        if listVC != nil && source != .list && positionToUse != nil && positionToUse!.index >= 0 {
            listVC!.selectRow(index: positionToUse!.index)
        }
    }

}

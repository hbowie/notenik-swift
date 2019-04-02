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
            var noteTabs: NoteTabsViewController?
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
            
            if editVC == nil {
                Logger.shared.log(skip: false, indent: 0, level: LogLevel.severe,
                                  message: "NoteEditViewController is nil")
            } else {
                editVC!.io = newValue
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
            noteTabs = noteItem?.viewController as? NoteTabsViewController
            noteTabs!.window = self
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
            editVC!.window = self
        }
    }
    
    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        
        guard let noteIO = notenikIO else { return }
        
        switch sender.selectedSegment {
        case 0:
            // Go to top of list
            modIfChanged(sender)
            let (note, position) = noteIO.firstNote()
            select(note: note, position: position, source: .nav)
        case 1:
            // Go to prior note
            modIfChanged(sender)
            let startingPosition = noteIO.position
            var (note, position) = noteIO.priorNote(startingPosition!)
            if note == nil {
                (note, position) = noteIO.lastNote()
            }
            select(note: note, position: position, source: .nav)
        case 2:
            // Go to next note
            modIfChanged(sender)
            let startingPosition = noteIO.position
            var (note, position) = noteIO.nextNote(startingPosition!)
            if note == nil {
                (note, position) = noteIO.firstNote()
            }
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
        
        if listVC != nil && source != .list && positionToUse != nil && positionToUse!.index >= 0 {
            listVC!.selectRow(index: positionToUse!.index)
        }
        if displayVC != nil  && noteToUse != nil {
            displayVC!.display(note: noteToUse!)
        }
        if editVC != nil && noteToUse != nil {
            editVC!.select(note: noteToUse!)
        }
    }
    
    /// Allow the user to add or delete a Note
    @IBAction func addOrDeleteNote(_ sender: NSSegmentedControl) {
        print ("CollectionWindowController.addOrDeleteNote")
        if sender.selectedSegment == 0 {
            print ("  - Adding a Note")
        } else {
            deleteNote(sender)
        }
    }
    
    @IBAction func newNote(_ sender: Any) {
        print ("CollectionWindowController.newNote")
    }
    
    /// Delete the Note
    @IBAction func deleteNote(_ sender: Any) {
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        let (selectedNote, _) = notenikIO!.getSelectedNote()
        guard selectedNote != nil else { return }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Really delete the Note titled '\(selectedNote!.title)'?"
        // alert.informativeText = "Informative Text"
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        // alert.showsSuppressionButton = true
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let (nextNote, nextPosition) = notenikIO!.deleteSelectedNote()
            reload()
            if nextNote != nil {
                select(note: nextNote, position: nextPosition, source: .action)
            }
        }
    }
    
    func reload() {
        listVC!.reload()
        tagsVC!.reload()
    }
    
    /// Duplicate the Selected Note
    @IBAction func duplicateNote(_ sender: Any) {
        print ("CollectionWindowController.duplicateNote")
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    @IBAction func modIfChanged(_ sender: Any) {
        
        guard editVC != nil else { return }
        
        editVC!.modIfChanged()
    }
    

    
    /// Take appropriate actions when the user has modified the note
    func noteModified(updatedNote: Note) {
        print ("CollectionWindowController. noteModified!")
        
        if displayVC != nil {
            displayVC!.display(note: updatedNote)
        }
    }
    
    @IBAction func makeCollectionEssential(_ sender: Any) {
        juggler.makeCollectionEssential(io: notenikIO!)
    }
    
    @IBAction func textEditNote(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let noteToUse = note else { return }
        if noteToUse.hasFileName() {
            NSWorkspace.shared.openFile(noteToUse.fullPath!)
        }
    }
    
    @IBAction func launchLink(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let noteToUse = note else { return }
        let url = noteToUse.linkAsURL
        if url != nil {
            NSWorkspace.shared.open(url!)
        }
    }
    
    @IBAction func sortByTitle(_ sender: Any) {
        setSortParm(.title)
    }
    
    @IBAction func sortBySeqAndTitle(_ sender: Any) {
        setSortParm(.seqPlusTitle)
    }
    
    @IBAction func sortTasksByDate(_ sender: Any) {
        setSortParm(.tasksByDate)
    }
    
    @IBAction func sortTasksBySeq(_ sender: Any) {
        setSortParm(.tasksBySeq)
    }
    
    @IBAction func sortByAuthor(_ sender: Any) {
        setSortParm(.author)
    }
    
    func setSortParm(_ sortParm: NoteSortParm) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortParm = sortParm
        lister.setSortParm(sortParm)
    }

}

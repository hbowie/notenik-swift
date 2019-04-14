//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CollectionWindowController: NSWindowController {
    
    @IBOutlet var shareButton: NSButton!
    
    let juggler:             CollectionJuggler = CollectionJuggler.shared
    var notenikIO:           NotenikIO?
    var windowNumber         = 0
    
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    
    var newNoteRequested = false
    var newNote: Note?
    
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
            window!.representedURL = notenikIO!.collection!.collectionFullPathURL
            if notenikIO!.collection!.title == "" {
                window!.title = notenikIO!.collection!.path
            } else {
                window!.title = notenikIO!.collection!.title
            }
            
            if self.window == nil {
                Logger.shared.log(skip: false, indent: 0, level: .severe,
                                  message: "Collection Window is nil!")
            } else {
                let window = self.window as? CollectionWindow
                window!.io = notenikIO
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
    
    @IBAction func menuCollectionPreferences(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        if let templateController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            // templateController.collection = io!.collection
            // templateController.showWindow(self)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Collection Prefs Window Controller!")
        }
    }
    
    /// Respond to the user's request to move forward, backwards, or back to start of list
    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        
        guard let noteIO = notenikIO else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        switch sender.selectedSegment {
        case 0:
            // Go to top of list
            let (note, position) = noteIO.firstNote()
            select(note: note, position: position, source: .nav)
        case 1:
            // Go to prior note
            let startingPosition = noteIO.position
            var (note, position) = noteIO.priorNote(startingPosition!)
            if note == nil {
                (note, position) = noteIO.lastNote()
            }
            select(note: note, position: position, source: .nav)
        case 2:
            // Go to next note
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
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        
        if sender.selectedSegment == 0 {
            newNote(sender)
        } else {
            deleteNote(sender)
        }
    }
    
    @IBAction func newNote(_ sender: Any) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        newNoteRequested = true
        newNote = Note(collection: notenikIO!.collection!)
        editVC!.populateFields(with: newNote!)
        noteTabs!.tabView.selectLastTabViewItem(sender)
    }
    
    /// Duplicate the Selected Note
    @IBAction func duplicateNote(_ sender: Any) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        let (selectedNote, _) = notenikIO!.getSelectedNote()
        guard selectedNote != nil else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        newNoteRequested = true
        newNote = Note(collection: notenikIO!.collection!)
        editVC!.populateFields(with: selectedNote!)
        noteTabs!.tabView.selectLastTabViewItem(sender)
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
    
    /// Reload the Collection Views when data has changed
    func reload() {
        listVC!.reload()
        tagsVC!.reload()
    }
    
    @IBAction func saveEdits(_ sender: Any) {
        modIfChanged()
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    func modIfChanged() -> modIfChangedOutcome {
        
        guard editVC != nil else { return .notReady }
        
        let (outcome, note) = editVC!.modIfChanged(newNoteRequested: newNoteRequested, newNote: newNote)
        
        if outcome == .add || outcome == .deleteAndAdd {
            reload()
            select(note: note, position: nil, source: .action)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome == .modify {
            noteModified(updatedNote: note!)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        }
        if outcome != .tryAgain {
            newNoteRequested = false
        }
        return outcome
    }
    
    /// Take appropriate actions when the user has modified the note
    func noteModified(updatedNote: Note) {
        if displayVC != nil {
            displayVC!.display(note: updatedNote)
        }
    }
    
    @IBAction func saveDocumentAs(_ sender: NSMenuItem) {
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        guard let window = self.window as? CollectionWindow else { return }
        juggler.userRequestsSaveAs(currentIO: io!, currentWindow: window)
    }
    
    @IBAction func makeCollectionEssential(_ sender: Any) {
        juggler.makeCollectionEssential(io: notenikIO!)
    }
    
    /// Reload the current collection from disk
    @IBAction func reloadCollection(_ sender: Any) {
        guard notenikIO != nil && notenikIO!.collection != nil && notenikIO!.collectionOpen else { return }
        let url = notenikIO!.collection!.collectionFullPathURL
        notenikIO!.closeCollection()
        let newIO: NotenikIO = FileIO()
        let realm = newIO.getDefaultRealm()
        realm.path = ""
        let collection = newIO.openCollection(realm: realm, collectionPath: url!.path)
        self.io = newIO
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
    
    @IBAction func reloadDisplayView(_ sender: Any) {
        guard displayVC != nil else { return }
        displayVC!.reload()
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

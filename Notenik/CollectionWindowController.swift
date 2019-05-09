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

class CollectionWindowController: NSWindowController, CollectionPrefsOwner {
    
    @IBOutlet var shareButton: NSButton!
    
    @IBOutlet var searchField: NSSearchField!
    
    let juggler:             CollectionJuggler = CollectionJuggler.shared
    var notenikIO:           NotenikIO?
    var windowNumber         = 0
    
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    let shareStoryboard:           NSStoryboard = NSStoryboard(name: "Share", bundle: nil)
    let displayPrefsStoryboard:    NSStoryboard = NSStoryboard(name: "DisplayPrefs", bundle: nil)
    
    var newNoteRequested = false
    var pendingMod = false
    var newNote: Note?
    var modInProgress = false
    
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
    
    /// Import additional notes from a comma- or tab-separated text file. 
    @IBAction func importDelimited(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }

        // Ask the user for a location on disk
        let openPanel = NSOpenPanel();
        openPanel.title = "Open an input tab- or comma-separated text file"
        let parent = io!.collection!.collectionFullPathURL!.deletingLastPathComponent()
        openPanel.directoryURL = parent
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) -> Void  in
            if result == .OK {
                let imports = self.io!.importDelimited(fileURL: openPanel.url!)
                Logger.shared.log(skip: false, indent: 0, level: .routine,
                                  message: "Imported \(imports) notes from \(openPanel.url!.path)")
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "Imported \(imports) notes from \(openPanel.url!.path)"
                alert.addButton(withTitle: "OK")
                _ = alert.runModal()
            }
        }
        reloadViews()
        let (note, position) = io!.firstNote()
        select(note: note, position: position, source: .nav)
    }
    
    /// Export Notes to a Comma-Separated Values File
    @IBAction func exportCSV(_ sender: Any) {
        guard let fileURL = getExportURL(fileExt: "csv") else { return }
        exportDelimited(fileURL: fileURL, sep: .comma)
    }
    
    /// Export Notes to a Tab-Delimited File
    @IBAction func exportTabDelim(_ sender: Any) {
        guard let fileURL = getExportURL(fileExt: "tab") else { return }
        exportDelimited(fileURL: fileURL, sep: .tab)
    }
    
    /// Ask the user where to save the export file
    func getExportURL(fileExt: String) -> URL? {
        guard io != nil && io!.collectionOpen else { return nil }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return nil }
        
        let savePanel = NSSavePanel();
        savePanel.title = "Specify an output file"
        let parent = io!.collection!.collectionFullPathURL
        if parent != nil {
            savePanel.directoryURL = parent!
        }
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "export." + fileExt
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
    
    /// Export a text file with fields separated by something-or-other
    func exportDelimited(fileURL: URL, sep: DelimitedSeparator) {
        let notesExported = io!.exportDelimited(fileURL: fileURL, sep: sep)

        let alert = NSAlert()
        if notesExported >= 0 {
            alert.alertStyle = .informational
            alert.messageText = "\(notesExported) Notes exported"
            alert.informativeText = "Notes written to '\(fileURL.path)'"
        } else {
            alert.alertStyle = .critical
            alert.messageText = "Problems exporting to disk"
            alert.informativeText = "Check Log for possible details"
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()

    }
    
    /// The user has requested a chance to review and possibly modify the Collection Preferences. 
    @IBAction func menuCollectionPreferences(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            collectionPrefsController.showWindow(self)
            collectionPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io!.collection!)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Collection Prefs Window Controller!")
        }
    }
    
    /// Let the calling class know that the user has completed modifications
    /// of the Collection Preferences.
    ///
    /// - Parameters:
    ///   - ok: True if they clicked on OK, false if they clicked Cancel.
    ///   - collection: The Collection whose prefs are being modified.
    ///   - window: The Collection Prefs window.
    func collectionPrefsModified(ok: Bool, collection: NoteCollection, window: CollectionPrefsWindowController) {
        window.close()
        guard ok else { return }
        guard io != nil && io!.collectionOpen else { return }
        io!.persistCollectionInfo()
        MasterCollection.shared.registerCollection(title: collection.title, collectionURL: collection.collectionFullPathURL!)
    }
    
    /// If we have past due daily tasks, then update the dates to make them current
    @IBAction func menuCatchUpDailyTasks(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        let today = DateValue("today")
        var notesToUpdate: [Note] = []
        var (note, position) = io!.firstNote()
        while note != nil {
            if note!.hasDate() && note!.hasRecurs() && !note!.isDone && note!.daily && note!.date < today {
                notesToUpdate.append(note!)
            }
            (note, position) = io!.nextNote(position)
        }
        for noteToUpdate in notesToUpdate {
            let modNote = noteToUpdate.copy() as! Note
            while modNote.date < today {
                modNote.recur()
            }
            io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        reloadViews()
        (note, position) = io!.firstNote()
        select(note: note, position: position, source: .nav)
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    @IBAction func menuNoteClose(_ sender: Any) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, notePosition) = io!.getSelectedNote()
        guard note != nil else { return }
        if (pendingMod || newNoteRequested) && noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.closeNote()
        } else {
            let modNote = note!.copy() as! Note
            modNote.close()
            let (nextNote, nextPosition) = io!.deleteSelectedNote()
            let (addedNote, addedPosition) = io!.addNote(newNote: modNote)
            if addedNote == nil {
                Logger.shared.log(skip: true, indent: 0, level: .severe,
                                  message: "Problems adding note titled \(modNote.title)")
            } else {
                noteModified(updatedNote: addedNote!)
                reloadViews()
                select(note: addedNote, position: nil, source: .action)
            }
        }
    }
    
    @IBAction func shareClicked(_ sender: NSView) {
        guard io != nil && io!.collectionOpen else { return }
        let (noteToShare, notePosition) = io!.getSelectedNote()
        guard noteToShare != nil else { return }
        let writer = BigStringWriter()
        let maker = NoteLineMaker(writer)
        let fieldsWritten = maker.putNote(noteToShare!)
        if fieldsWritten > 0 {
            let stringToShare = NSString(string: writer.bigString)
            let picker = NSSharingServicePicker(items: [stringToShare])
            picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
        }
    }
    
    @IBAction func menuNoteShare(_ sender: Any) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, notePosition) = io!.getSelectedNote()
        guard note != nil else { return }
        if let shareController = self.shareStoryboard.instantiateController(withIdentifier: "shareWC") as? ShareWindowController {
            guard let vc = shareController.contentViewController as? ShareViewController else { return }
            shareController.showWindow(sender)
            vc.window = shareController
            vc.note = note
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Share Window Controller!")
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
            goToFirstNote(sender)
        case 1:
            // Go to prior note
            goToPriorNote(sender)
        case 2:
            // Go to next note
            goToNextNote(sender)
        default:
            let startingPosition = noteIO.position
        }
    }
    
    /// Go to the first note in the list
    @IBAction func goToFirstNote(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        let (note, position) = noteIO.firstNote()
        select(note: note, position: position, source: .nav)
    }
    
    /// Go to the next note in the list
    @IBAction func goToNextNote(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        let startingPosition = noteIO.position
        var (note, position) = noteIO.nextNote(startingPosition!)
        if note == nil {
            (note, position) = noteIO.firstNote()
        }
        select(note: note, position: position, source: .nav)
    }
    
    /// Go to the prior note in the list
    @IBAction func goToPriorNote(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        let startingPosition = noteIO.position
        var (note, position) = noteIO.priorNote(startingPosition!)
        if note == nil {
            (note, position) = noteIO.lastNote()
        }
        select(note: note, position: position, source: .nav)
    }
    
    @IBAction func findNote(_ sender: Any) {
        guard let confirmedWindow = self.window else { return }
        confirmedWindow.makeFirstResponder(searchField)
    }
    
    @IBAction func searchNow(_ sender: Any) {
        guard let searchField = sender as? NSSearchField else { return }
        let searchString = searchField.stringValue
        let searchFor = searchString
        guard searchString.count > 0 else { return }
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        var found = false
        var (note, position) = noteIO.firstNote()
        while !found && note != nil {
            found = searchNote(note!, for: searchFor)
            if !found {
                (note, position) = noteIO.nextNote(position)
            }
        }
        if found {
            select(note: note, position: position, source: .action)
        } else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "No Note found containing search string '\(searchFor)'"
            alert.informativeText = "Searched for case-insensitve match on title, link, tags and body fields"
            
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
        }
    }
    
    @IBAction func searchForNext(_ sender: Any) {
        let searchString = searchField.stringValue
        let searchFor = searchString
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        var (note, position) = noteIO.getSelectedNote()
        guard note != nil && position.valid else { return }
        (note, position) = noteIO.nextNote(position)
        var found = false
        while !found && note != nil {
            found = searchNote(note!, for: searchFor)
            if !found {
                (note, position) = noteIO.nextNote(position)
            }
        }
        if found {
            select(note: note, position: position, source: .action)
        } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "No more notes found containing search string '\(searchFor)'"
            alert.informativeText = "Searched for case-insensitve match on title, link, tags and body fields"
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
        }
    }
    
    func searchNote(_ note: Note, for searchFor: String) -> Bool {
        if note.title.value.lowercased().contains(searchFor) {
            return true
        }
        if note.link.value.lowercased().contains(searchFor) {
            return true
        }
        if note.tags.value.lowercased().contains(searchFor) {
            return true
        }
        if note.body.value.lowercased().contains(searchFor) {
            return true
        }
        return false
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
        noteTabs!.tabView.selectTabViewItem(at: 1)
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
            reloadViews()
            if nextNote != nil {
                select(note: nextNote, position: nextPosition, source: .action)
            }
        }
    }
    
    /// Reload the Collection Views when data has changed
    func reloadViews() {
        listVC!.reload()
        tagsVC!.reload()
    }
    
    @IBAction func saveEdits(_ sender: Any) {
        modIfChanged()
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    func modIfChanged() -> modIfChangedOutcome {
        guard editVC != nil else { return .notReady }
        guard newNoteRequested || pendingMod else { return .noChange }
        let (outcome, note) = editVC!.modIfChanged(newNoteRequested: newNoteRequested, newNote: newNote)
        if outcome != .tryAgain {
            newNoteRequested = false
            pendingMod = false
        }
        if outcome == .add || outcome == .deleteAndAdd {
            reloadViews()
            select(note: note, position: nil, source: .action)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome == .modify {
            noteModified(updatedNote: note!)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome != .tryAgain {
            noteTabs!.tabView.selectFirstTabViewItem(nil)
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
        newNoteRequested = false
        pendingMod = false
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
    
    /// Launch a Note's Link
    @IBAction func launchLink(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let noteToUse = note else { return }
        let url = noteToUse.linkAsURL
        if url != nil {
            if noteIO.collection!.master {
                juggler.openFileWithNewWindow(fileURL: url!, readOnly: false)
            } else {
                NSWorkspace.shared.open(url!)
            }
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
    
    @IBAction func displayPrefs(_ sender: Any) {
        if let displayPrefsController = self.displayPrefsStoryboard.instantiateController(withIdentifier: "displayPrefsWC") as? DisplayPrefsWindowController {
            displayPrefsController.showWindow(self)
            // displayPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io!.collection!)
        } else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.severe,
                              message: "Couldn't get a Display Prefs Window Controller!")
        }
    }

}

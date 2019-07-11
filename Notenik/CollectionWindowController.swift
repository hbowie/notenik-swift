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
    
    @IBOutlet var actionMenu: NSMenu!
    
    let juggler  = CollectionJuggler.shared
    let appPrefs = AppPrefs.shared
    let osdir    = OpenSaveDirectory.shared
    
    var notenikIO:           NotenikIO?
    var windowNumber         = 0
    
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    let shareStoryboard:           NSStoryboard = NSStoryboard(name: "Share", bundle: nil)
    let displayPrefsStoryboard:    NSStoryboard = NSStoryboard(name: "DisplayPrefs", bundle: nil)
    
    // Has the user requested the opportunity to add a new Note to the Collection?
    var newNoteRequested = false
    
    // Do we have a selected Note that might have been edited?
    var pendingEdits = false
    
    // Is modIfChanged logic in progress? (Test to prevent unintended recursion.)
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
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Collection Window is nil!")
            } else {
                let window = self.window as? CollectionWindow
                window!.io = notenikIO
            }
            
            if listVC == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "NoteListViewController is nil!")
            } else {
                listVC!.io = newValue
            }
            
            if tagsVC == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message:"NoteTagsView Controller is nil!")
            } else {
                tagsVC!.io = newValue
            }
            
            if editVC == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "NoteEditViewController is nil")
            } else {
                editVC!.io = newValue
            }
            let (selected, position) = notenikIO!.firstNote()
            select(note: selected, position: position, source: .nav)
            
            var i = actionMenu.numberOfItems - 1
            while i > 0 {
                actionMenu.removeItem(at: i)
                i -= 1
            }

            for report in notenikIO!.reports {
                let title = String(describing: report)
                let reportItem = NSMenuItem(title: title, action: #selector(runReport), keyEquivalent: "")
                actionMenu.addItem(reportItem)
            }
        }
    }
    
    @objc func runReport(_ sender: NSMenuItem) {
        
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        var found = false
        var i = 0
        while i < io!.reports.count && !found {
            let reportTitle = String(describing: noteIO.reports[i])
            found = (sender.title == reportTitle)
            if found {
                let template = Template()
                if noteIO.reportsFullPath != nil {
                    let templateURL = noteIO.reports[i].getURL(folderPath: noteIO.reportsFullPath!)
                    var ok = template.openTemplate(templateURL: templateURL!)
                    if ok {
                        template.supplyData(io: noteIO)
                        ok = template.generateOutput()
                    }
                }
            } else {
                i += 1
            }
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
    
    /// The user has requested a chance to review and possibly modify the Collection Preferences. 
    @IBAction func menuCollectionPreferences(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            collectionPrefsController.showWindow(self)
            collectionPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: io!.collection!)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
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
    
    @IBAction func standardizeDatesToYMD(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        var (note, position) = noteIO.firstNote()
        var updated = 0
        while note != nil {
            if note!.hasDate() {
                let ymdDate = note!.date.ymdDate
                let dateSet = note!.setDate(ymdDate)
                let written = noteIO.writeNote(note!)
                if !written {
                    print("Problems saving the note to disk")
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "CollectionWindowController",
                                      level: .error,
                                      message: "Problems saving note titled \(note!.title)")
                } else {
                    updated += 1
                }
            }
            (note, position) = noteIO.nextNote(position)
        }
        finishBatchOperation()
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "\(updated) Notes were updated"
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    /// Ask the user to pick a file or folder and set the link field to the local URL
    @IBAction func setLocalLink(_ sender: Any) {

        // See if we have what we need to proceed
        guard !pendingMod else { return }
        guard io != nil && io!.collectionOpen else { return }
        guard let noteIO = io else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let selNote = note else { return }
        guard noteIO.collection!.dict.contains(LabelConstants.link) else { return }

        // Ask the user to pick a local file or folder
        let openPanel = NSOpenPanel();
        openPanel.title = "Select a File or Folder"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }
        
        // Now let's make the appropriate updates
        let localLink = openPanel.url!.absoluteString
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.setLink(localLink)
        } else {
            let setOK = selNote.setLink(localLink)
            if !setOK {
                logUnlikelyProblem("Attempt to set link value for selected note failed!")
            }
            editVC!.populateFields(with: selNote)
            let writeOK = noteIO.writeNote(selNote)
            if !writeOK {
                logUnlikelyProblem("Attempted write of updated note failed!")
            }
            noteModified(updatedNote: selNote)
            reloadViews()
            select(note: selNote, position: nil, source: .action)
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    @IBAction func menuNoteClose(_ sender: Any) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, notePosition) = io!.getSelectedNote()
        guard note != nil else { return }
        
        // if (pendingMod || newNoteRequested) && noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.closeNote()
        } else {
            let modNote = note!.copy() as! Note
            modNote.close()
            let (nextNote, nextPosition) = io!.deleteSelectedNote()
            let (addedNote, addedPosition) = io!.addNote(newNote: modNote)
            if addedNote == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Problems adding note titled \(modNote.title)")
            } else {
                noteModified(updatedNote: addedNote!)
                reloadViews()
                select(note: addedNote, position: nil, source: .action)
            }
        }
    }
    
    /// Increment either the Seq field or the Date field
    @IBAction func menuNoteIncrement(_ sender: Any) {
        
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        
        let modNote = selNote.copy() as! Note
        let sortParm = noteIO.collection!.sortParm
        
        // Determine which field to increment
        if !selNote.hasSeq() && !selNote.hasDate() {
            return
        } else if selNote.hasSeq() && !selNote.hasDate() {
            incrementSeq(noteIO: noteIO, note: selNote, modNote: modNote)
        } else if selNote.hasDate() && !selNote.hasDate() {
            incrementDate(noteIO: noteIO, note: selNote, modNote: modNote)
        } else if sortParm == .seqPlusTitle || sortParm == .tasksBySeq {
            incrementSeq(noteIO: noteIO, note: selNote, modNote: modNote)
        } else {
            incrementDate(noteIO: noteIO, note: selNote, modNote: modNote)
        }
    }
    
    /// Increment the Note's Date field by one day.
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use.
    ///   - note: The note prior to being incremented.
    ///   - modNote: A copy of the note being incremented.
    func incrementDate(noteIO: NotenikIO, note: Note, modNote: Note) {
        let incDate = SimpleDate(dateValue: note.date)
        if incDate.goodDate {
            incDate.addDays(1)
            let strDate = String(describing: incDate)
            modNote.setDate(strDate)
            recordMods(noteIO: noteIO, note: note, modNote: modNote)
        }
    }
    
    /// Increment the Note's Seq field by one.
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use.
    ///   - note: The note prior to being incremented.
    ///   - modNote: A copy of the note being incremented.
    func incrementSeq(noteIO: NotenikIO, note: Note, modNote: Note) {
        guard note.seq.value.count > 0 else { return }
        let incSeq = SeqValue(note.seq.value)
        incSeq.increment(onLeft: false)
        if noteIO.collection!.sortParm == .seqPlusTitle || noteIO.collection!.sortParm == .tasksBySeq {
            let position = noteIO.positionOfNote(note)
            let (nextNote, _) = noteIO.nextNote(position)
            if nextNote != nil {
                incrementSeq(noteIO: noteIO, lastSeq: incSeq, nextNote: nextNote!)
            }
        }
        _ = noteIO.positionOfNote(modNote)
        _ = modNote.setSeq(String(describing: incSeq))
        _ = recordMods(noteIO: noteIO, note: note, modNote: modNote)
        select(note: modNote, position: nil, source: .action)
    }
    
    /// See if the next Note needs to be incremented, and increment it and following
    /// Notes if so. This function is called recursively.
    ///
    /// - Parameters:
    ///   - noteIO: The Notenik Input/Output module to use.
    ///   - lastSeq: The incremented sequence value for the Note just prior to this one.
    ///   - nextNote: The next Note following the previous one.
    func incrementSeq(noteIO: NotenikIO, lastSeq: SeqValue, nextNote: Note) {
        if lastSeq.sortKey == nextNote.seq.sortKey {
            let incSeq = SeqValue(nextNote.seq.value)
            incSeq.increment(onLeft: false)
            var position = noteIO.positionOfNote(nextNote)
            let (followingNote, _) = noteIO.nextNote(position)
            if followingNote != nil {
                incrementSeq(noteIO: noteIO, lastSeq: incSeq, nextNote: followingNote!)
            }
            position = noteIO.positionOfNote(nextNote)
            _ = nextNote.setSeq(incSeq.value)
            let writeOK = noteIO.writeNote(nextNote)
            if !writeOK {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .error,
                                  message: "Trouble writing updates for Note titled '\(nextNote.title.value)'")
            }
        } // End if we have another note that needs incrementing
    } // end of func
    
    /// Record modifications made to the Selected Note
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use
    ///   - note: The note that's been changed.
    ///   - modNote: The note with modifications.
    /// - Returns: True if changes were recorded successfully; false otherwise.
    func recordMods (noteIO: NotenikIO, note: Note, modNote: Note) -> Bool {
        let (_, _) = noteIO.deleteSelectedNote()
        let (addedNote, _) = noteIO.addNote(newNote: modNote)
        if addedNote == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .error,
                              message: "Problems adding note titled \(modNote.title)")
            return false
        } else {
            noteModified(updatedNote: addedNote!)
            editVC!.populateFields(with: addedNote!)
            reloadViews()
            select(note: addedNote, position: nil, source: .action)
            return true
        }
    }
    
    @IBAction func shareClicked(_ sender: NSView) {
        guard io != nil && io!.collectionOpen else { return }
        let (noteToShare, _) = io!.getSelectedNote()
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
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
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
    
    /// Respond to the user's request to add a new note to the collection.
    @IBAction func newNote(_ sender: Any) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        let (selection, _) = notenikIO!.getSelectedNote()
        
        newNoteRequested = true
        newNote = Note(collection: notenikIO!.collection!)
        
        if selection != nil && selection!.hasSeq() {
            let incSeq = SeqValue(selection!.seq.value)
            incSeq.increment(onLeft: false)
            newNote!.setSeq(incSeq.value)
        }
        
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
        
        var proceed = true
        if appPrefs.confirmDeletes {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Really delete the Note titled '\(selectedNote!.title)'?"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                proceed = false
            }
        }
        if proceed {
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
        if !pendingMod {
            modIfChanged()
        }
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    func modIfChanged() -> modIfChangedOutcome {
        // print("CollectionWindowController.modIfChanged")
        guard editVC != nil else { return .notReady }
        guard !pendingMod else { return .notReady }
        guard newNoteRequested || pendingEdits else { return .noChange }
        pendingMod = true
        let (outcome, note) = editVC!.modIfChanged(newNoteRequested: newNoteRequested, newNote: newNote)
        if outcome != .tryAgain {
            newNoteRequested = false
        }
        if outcome != .tryAgain && outcome != .noChange {
            pendingEdits = false
            // print("  - pendingEdits set to false")
        }
        if outcome == .add || outcome == .deleteAndAdd || outcome == .modify {
            editVC!.populateFields(with: note!)
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
        pendingMod = false
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
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        let url = notenikIO!.collection!.collectionFullPathURL
        notenikIO!.closeCollection()
        newNoteRequested = false
        pendingMod = false
        pendingEdits = false
        let newIO: NotenikIO = FileIO()
        let realm = newIO.getDefaultRealm()
        realm.path = ""
        let collection = newIO.openCollection(realm: realm, collectionPath: url!.path)
        self.io = newIO
    }
    
    @IBAction func textEditNote(_ sender: Any) {
        guard let noteIO = notenikIO else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
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
        let possibleURL = noteToUse.linkAsURL
        guard let url = possibleURL else { return }
        var urlPointsToCollection = false
        if url.isFileURL && url.hasDirectoryPath {
            let folderPath = url.path
            let infoPath = FileUtils.joinPaths(path1: folderPath, path2: FileIO.infoFileName)
            let infoURL = URL(fileURLWithPath: infoPath)
            do {
                let reachable = try infoURL.checkResourceIsReachable()
                urlPointsToCollection = reachable
            } catch {
                urlPointsToCollection = false
            }
        }
        
        if noteIO.collection!.isRealmCollection || urlPointsToCollection {
            juggler.openFileWithNewWindow(fileURL: url, readOnly: false)
        } else {
            NSWorkspace.shared.open(url)
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
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Display Prefs Window Controller!")
        }
    }
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code contains import, export and archive routines.
    //
    // ----------------------------------------------------------------------------------
    
    
    /// Purge closed Notes from this Collection
    @IBAction func userRequestsPurge(_ sender: Any) {
        
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        // Make sure we have a status field for this collection
        let dict = noteIO.collection!.dict
        if !dict.contains(LabelConstants.status) {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Cannot perform a Purge since the Collection does not use the Status field"
            alert.addButton(withTitle: "Cancel")
            let _ = alert.runModal()
            return
        }
        
        // Ask the user for direction
        var archive = false
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Purge closed Notes?"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Purge and Archive")
        alert.addButton(withTitle: "Purge and Discard")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return
        } else if response == .alertSecondButtonReturn {
            archive = true
        }
        
        // Let's perform the purge
        if archive {
            let openPanel = juggler.prepCollectionOpenPanel()
            openPanel.begin { (result) -> Void  in
                if result == .OK {
                    self.purge(archiveURL: openPanel.url!)
                }
            }
        } else {
            purge(archiveURL: nil)
        }
    }
    
    /// Now actually perform the purge
    func purge(archiveURL: URL?) {
        var archiveIO: NotenikIO?
        if archiveURL != nil {
            archiveIO = FileIO()
            let archiveRealm = archiveIO!.getDefaultRealm()
            archiveRealm.path = ""
            let archiveCollection = archiveIO!.openArchive(primeIO: io!, archivePath: archiveURL!.path)
            if archiveCollection == nil {
                return
            }
        }
        let purgeCount = io!.purgeClosed(archiveIO: archiveIO)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "\(purgeCount) Notes purged from Collection at \(io!.collection!.collectionFullPath)")
        reloadViews()
        let (note, position) = io!.firstNote()
        select(note: note, position: position, source: .nav)
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "\(purgeCount) Notes purged from the Collection"
        if archiveURL != nil {
            alert.informativeText = "Archived to \(archiveURL!.path)"
        }
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
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
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .info,
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
    
    /// Import the notes from another Notenik Collection
    @IBAction func importNotenik(_ sender: Any) {

        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        // Ask the user for an import location
        let openPanel = juggler.prepCollectionOpenPanel()
        openPanel.canCreateDirectories = false
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }

        let importIO: NotenikIO = FileIO()
        let importRealm = importIO.getDefaultRealm()
        let importURL = openPanel.url!
        importRealm.path = ""
        let importCollection = importIO.openCollection(realm: importRealm, collectionPath: importURL.path)
        guard importCollection != nil else {
            blockingAlert(msg: "The import location does not seem to be a valid Notenik Collection",
                          info: "Attempted to import from \(importURL.path)")
            return
        }

        // OK, let's import
        var imported = 0
        var rejected = 0
        var (importNote, importPosition) = importIO.firstNote()
        while importNote != nil && importPosition.valid {
            let noteCopy = importNote!.copy() as! Note
            noteCopy.collection = noteIO.collection!
            let (importedNote, _) = noteIO.addNote(newNote: noteCopy)
            if importedNote == nil {
                rejected += 1
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .error,
                                  message: "Could not import note titled '\(importNote!.title.value)'")
            } else {
                imported += 1
            }
            (importNote, importPosition) = importIO.nextNote(importPosition)
        }
        
        if rejected > 0 {
            blockingAlert(msg: "\(rejected) Notes could not be imported", info: "See the Log Window for details")
        }
        let ok = imported > 0
        informUserOfImportExportResults(operation: "import", ok: ok, numberOfNotes: imported, path: importURL.path)
        
        finishBatchOperation()
    }
    
    /// Export Notes to a Comma-Separated Values File
    @IBAction func exportCSV(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let fileURL = getExportURL(fileExt: "csv") else { return }
        exportDelimited(noteIO: noteIO, fileURL: fileURL, sep: .comma)
    }
    
    /// Export Notes to a Tab-Delimited File
    @IBAction func exportTabDelim(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let fileURL = getExportURL(fileExt: "tab") else { return }
        exportDelimited(noteIO: noteIO, fileURL: fileURL, sep: .tab)
    }
    
    @IBAction func splitTagsTabDelim(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let fileURL = getExportURL(fileExt: "tab") else { return }
        splitDelimited(noteIO: noteIO, fileURL: fileURL, sep: .tab)
    }
    
    @IBAction func splitTagsCSV(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let fileURL = getExportURL(fileExt: "csv") else { return }
        splitDelimited(noteIO: noteIO, fileURL: fileURL, sep: .comma)
    }
    
    @IBAction func favoritesToHTML(_ sender: Any) {
        print("Favorites to HTML")
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        guard let fileURL = getExportURL(fileExt: "html", fileName: "favorites") else { return }
        let favsToHTML = FavoritesToHTML(noteIO: noteIO, outURL: fileURL)
        favsToHTML.generate()
    }
    
    /// Ask the user where to save the export file
    func getExportURL(fileExt: String, fileName: String = "export") -> URL? {
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
        savePanel.nameFieldStringValue = fileName + "." + fileExt
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
    
    /// Export a text file with fields separated by something-or-other
    func exportDelimited(noteIO: NotenikIO, fileURL: URL, sep: DelimitedSeparator) {
        let notesExported = noteIO.exportDelimited(fileURL: fileURL, sep: sep)
        let ok = notesExported > 0
        informUserOfImportExportResults(operation: "export",
                                        ok: ok,
                                        numberOfNotes: notesExported,
                                        path: fileURL.path)
    }
    
    /// Export a text file, with one note for each tag.
    func splitDelimited(noteIO: NotenikIO, fileURL: URL, sep: DelimitedSeparator) {
        let notesExported = noteIO.splitDelimited(fileURL: fileURL, sep: sep)
        let ok = notesExported > 0
        informUserOfImportExportResults(operation: "split tags",
                                        ok: ok,
                                        numberOfNotes: notesExported,
                                        path: fileURL.path)
    }
    
    /// Export the current collection in Notenik format.
    @IBAction func exportNotenik(_ sender: Any) {
        
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        let collectionURL = noteIO.collection!.collectionFullPathURL!
        
        let openPanel = juggler.prepCollectionOpenPanel()
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }
        
        let exportURL = openPanel.url!
        
        var ok = true
        var numberOfNotes = 0
        do {
            try FileManager.default.removeItem(at: exportURL)
            try FileManager.default.copyItem(at: collectionURL, to: exportURL)
            numberOfNotes = noteIO.notesCount
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Could not Export current Collection to selected folder")
            ok = false
        }
        informUserOfImportExportResults(operation: "export", ok: ok, numberOfNotes: numberOfNotes, path: exportURL.path)
    }
    
    /// Let the user know the results of an import/export operation
    ///
    /// - Parameters:
    ///   - operation: Either "import" or "export"
    ///   - ok: Was the operation successful?
    ///   - numberOfNotes: Number of notes imported or exported.
    ///   - path: The path to the export destination or the import source.
    func informUserOfImportExportResults(operation: String, ok: Bool, numberOfNotes: Int, path: String) {
        let alert = NSAlert()
        if ok {
            alert.alertStyle = .informational
            alert.messageText = "\(StringUtils.toUpperFirstChar(operation)) operation was performed on \(numberOfNotes) Notes"
            if operation == "import" {
                alert.informativeText = "Notes imported from '\(path)'"
            } else {
                alert.informativeText = "Notes exported to \(path)"
            }
        } else {
            alert.alertStyle = .critical
            if operation == "import" {
                alert.messageText = "Problems importing from \(path)"
            } else {
                alert.messageText = "Problems exporting to \(path)"
            }
            alert.informativeText = "Check Log Window for possible details"
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code contains internal utility routines.
    //
    // ----------------------------------------------------------------------------------

    /// See if we're ready to do something with a selected note.
    ///
    /// - Returns: The I/O module and the selected Note (both optionals)
    func guardForNoteAction() -> (NotenikIO?, Note?) {
        guard !pendingMod else { return (nil, nil) }
        guard io != nil && io!.collectionOpen else { return (nil, nil) }
        let (note, _) = io!.getSelectedNote()
        guard note != nil else { return (io!, nil) }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return (io!, nil) }
        return (io!, note!)
    }
    

    /// See if we're ready to do something affecting multiple Notes in the Collection.
    ///
    /// - Returns: The Notenik I/O module to use, if we're ready to go, otherwise nil.
    func guardForCollectionAction() -> NotenikIO? {
        guard !pendingMod else { return nil }
        guard io != nil && io!.collectionOpen else { return nil }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return nil }
        return io
    }
    
    /// Notify the user via a modal alert box that something has gone wrong,
    /// and the requested operation cannot be completed.
    ///
    /// - Parameters:
    ///   - msg: The message to be displayed.
    ///   - info: Optional additional informative text to be displayed.
    func blockingAlert(msg: String, info: String?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = msg
        if info != nil && info!.count > 0 {
            alert.informativeText = info!
        }
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
    }
    
    func logUnlikelyProblem(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .error,
                          message: msg)
    }
    
    /// Finish up batch operations by reloading the lists and selecting the first note
    func finishBatchOperation() {
        reloadViews()
        let (note, position) = io!.firstNote()
        select(note: note, position: position, source: .nav)
    }
}

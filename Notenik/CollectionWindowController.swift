//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import StoreKit

import NotenikUtils
import NotenikLib

/// Controls a window showing a particular Collection of Notes.
class CollectionWindowController: NSWindowController, AttachmentMasterController {
    
    @IBOutlet var shareButton: NSButton!
    
    @IBOutlet var searchField: NSSearchField!
    
    /// The Reports Action Menu.
    @IBOutlet var actionMenu: NSMenu!
    
    @IBOutlet var attachmentsMenu: NSMenu!
    
    let application = NSApplication.shared
    let juggler  = CollectionJuggler.shared
    let appPrefs = AppPrefs.shared
    let osdir    = OpenSaveDirectory.shared
    
    let filesTitle = "files..."
    let addAttachmentTitle = "Add Attachment..."
    
    var notenikIO:           NotenikIO?
    var preferredExt = ""
    var crumbs:              NoteCrumbs?
    var webLinkFollowed      = false
    var windowNumber         = 0
    
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    let shareStoryboard:           NSStoryboard = NSStoryboard(name: "Share", bundle: nil)
    let mediumPubStoryboard:       NSStoryboard = NSStoryboard(name: "MediumPub", bundle: nil)
    let microBlogStoryboard:       NSStoryboard = NSStoryboard(name: "MicroBlog", bundle: nil)
    let exportStoryboard:          NSStoryboard = NSStoryboard(name: "Export", bundle: nil)
    let attachmentStoryboard:      NSStoryboard = NSStoryboard(name: "Attachment", bundle: nil)
    let tagsMassChangeStoryboard:  NSStoryboard = NSStoryboard(name: "TagsMassChange", bundle: nil)
    
    // Has the user requested the opportunity to add a new Note to the Collection?
    var newNoteRequested = false
    
    // Do we have a selected Note that might have been edited?
    var pendingEdits = false
    
    // Is modIfChanged logic in progress? (Test to prevent unintended recursion.)
    var pendingMod = false
    
    var pendingPromise = false
    
    var newNote: Note?
    var modInProgress = false
    
    var emailPromised = false
    
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
            crumbs = NoteCrumbs(io: newValue!)
            window!.representedURL = notenikIO!.collection!.fullPathURL
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
            
            var (selected, position) = notenikIO!.getSelectedNote()
            if selected == nil {
                (selected, position) = notenikIO!.firstNote()
            } else {
                select(note: selected, position: position, source: .nav)
            }
            
            buildReportsActionMenu()
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
            
            if displayVC != nil {
                displayVC!.wc = self
            }
        }
    }
    
    func windowWillClose() {
        juggler.windowClosing(window: self)
    }
    
    /// The user has requested a chance to review and possibly modify the Collection Preferences. 
    @IBAction func menuCollectionPreferences(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        preferredExt = noteIO.collection!.preferredExt
        
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            if let collectionPrefsWindow = collectionPrefsController.window {
                let collectionPrefsVC = collectionPrefsWindow.contentViewController as! CollectionPrefsViewController
                collectionPrefsVC.passCollectionPrefsRequesterInfo(collection: noteIO.collection!, window: collectionPrefsController)
                let returnCode = application.runModal(for: collectionPrefsWindow)
                if returnCode == NSApplication.ModalResponse.OK {
                    collectionPrefsModified()
                }
                // collectionPrefsWindow.close()
            }
            // collectionPrefsController.showWindow(self)
            // collectionPrefsController.passCollectionPrefsRequesterInfo(owner: self, collection: noteIO.collection!)
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
    func collectionPrefsModified() {
        guard let noteIO = guardForCollectionAction() else { return }
        if noteIO.collection!.preferredExt != preferredExt {
            if noteIO is FileIO {
                let fileIO = noteIO as! FileIO
                let renameOK = fileIO.changePreferredExt(from: preferredExt,
                                                         to: fileIO.collection!.preferredExt)
                if !renameOK {
                    noteIO.collection!.preferredExt = preferredExt
                }
            }
        }
        noteIO.persistCollectionInfo()
        reloadCollection(self)
    }
    
    /// The user has requested an export of this Collection. 
    @IBAction func menuExport(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        if let exportController = self.exportStoryboard.instantiateController(withIdentifier: "exportWC") as? ExportWindowController {
            exportController.io = noteIO
            exportController.showWindow(self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get an Export Window Controller!")
        }
    }
    
    func updateNote(title: String, bodyText: String) {
        guard title.count > 0 else {
            return
        }
        guard let noteIO = guardForCollectionAction() else { return }
        let titleID = StringUtils.toCommon(title)
        let noteToUpdate = noteIO.getNote(forID: titleID)
        if noteToUpdate == nil {
            newNote(title: title, bodyText: bodyText)
        } else {
            updateNote(noteToUpdate: noteToUpdate!, bodyText: bodyText)
        }
    }
    
    func updateNote(noteToUpdate: Note, bodyText: String) {
        
        guard bodyText.count > 0 else { return }
        guard let _ = guardForCollectionAction() else { return }
        select(note: noteToUpdate, position: nil, source: .action)
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        var body = selectedNote.body.value
        let updatedNote = selectedNote.copy() as! Note
        body.append("\n\n")
        body.append(bodyText)
        guard updatedNote.setBody(body) else { return }
        newNoteRequested = false
        editVC!.populateFields(with: updatedNote)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    func newNote(title: String, bodyText: String) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        _ = newNote!.setTitle(title)
        _ = newNote!.setBody(bodyText)
        editVC!.populateFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Batch operations performed on the entire Collection.
    //
    // -----------------------------------------------------------
    
    let levelsHead = "levels-outline"
    
    /// Renumber the Collection's sequence numbers based on the level and position of each note.
    @IBAction func renumberSeqBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: true, updateTags: false)
    }
    
    @IBAction func replaceTagsBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: false, updateTags: true)
    }
    
    @IBAction func updateSeqAndTagsBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: true, updateTags: true)
    }
    
    /// Update Seq and/or Tags field based on outline structure (based on seq + level).
    func outlineUpdatesBasedOnLevel(updateSeq: Bool, updateTags: Bool) {
        
        // Make sure we're in a position to perform this operation.
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        let dict = collection.dict
        
        let levelDef = collection.levelFieldDef
        guard dict.contains(levelDef) else {
            communicateError("The Collection must contain a Level field before it can be Renumbered or Retagged", alert: true)
            return
        }
        
        guard collection.seqFieldDef != nil else {
            communicateError("The Collection must contain a Seq field before it can be Renumbered or Retagged", alert: true)
            return
        }
        
        let sortParm = collection.sortParm
        guard sortParm == .seqPlusTitle else {
            communicateError("First Sort by Seq + Title before attempting to Renumber or Retag", alert: true)
            return
        }
        
        // Go through the Collection, dentifying Notes that need updating.
        let low = collection.levelConfig.low
        let high = collection.levelConfig.high
        var first = true
        
        var numbers: [Int] = []
        while numbers.count <= high {
            numbers.append(0)
        }
        
        var parents: [String] = []
        while parents.count <= high {
            parents.append("")
        }
        
        var lastLevel = 0
        var startNumberingAt = low
        var tagStart = low
        var notesToUpdate: [Note] = []
        var updatedSeqs: [String] = []
        var updatedTags: [String] = []
        
        var (note, position) = noteIO.firstNote()
        while note != nil {
            
            // Process the next note.
            let noteLevel = note!.level.getInt()
            
            // Calculate the new seq value.
            var newSeq = ""
            if first && !note!.hasSeq() && noteLevel == low {
                startNumberingAt = low + 1
                tagStart = low + 1
            } else {
                while lastLevel > noteLevel {
                    numbers[lastLevel] = 0
                    parents[lastLevel] = ""
                    lastLevel -= 1
                }
                lastLevel = noteLevel
                numbers[noteLevel] += 1
                var i = startNumberingAt
                while i <= noteLevel {
                    if numbers[i] > 0 {
                        if newSeq.count > 0 { newSeq.append(".") }
                        newSeq.append(String(numbers[i]))
                    }
                    i += 1
                }
            }
            
            // Generate the new tags.
            var levelsTagForThisLevel = ""
            if updateSeq {
                if noteLevel >= startNumberingAt {
                    levelsTagForThisLevel.append(String(numbers[noteLevel]))
                    if levelsTagForThisLevel.count > 0 {
                        levelsTagForThisLevel.append(" ")
                    }
                }
            }
            let tagTitle = TagsValue.tagify(note!.title.value)
            levelsTagForThisLevel.append(tagTitle)
            parents[noteLevel] = levelsTagForThisLevel
            
            var newLevelTags = ""
            newLevelTags.append(levelsHead)
            var tagEnd = noteLevel
            if tagEnd == high {
                tagEnd = noteLevel - 1
            }
            if tagEnd < low {
                tagEnd = low
            }
            var j = tagStart
            while j <= tagEnd {
                if parents[j].count > 0 {
                    if newLevelTags.count > 0 { newLevelTags.append(".") }
                    newLevelTags.append(parents[j])
                }
                j += 1
            }
            
            // Now generate the new tags, preserving any non-level related tags assigned by the user.
            var newTags = ""
            let currTags = note!.tags
            var replaced = false
            for tagValue in currTags.tags {
                let tag = tagValue.value
                if tag.hasPrefix(levelsHead) {
                    if newTags.count > 0 { newTags.append(",") }
                    newTags.append(newLevelTags)
                    replaced = true
                } else {
                    if newTags.count > 0 { newTags.append(",") }
                    newTags.append(tag)
                }
            }
            if !replaced {
                if newTags.count > 0 { newTags.append(",") }
                newTags.append(newLevelTags)
            }
            
            // Now store any updates, so that we can apply them later.
            var updateNote = false
            
            if updateSeq && newSeq != note!.seq.value {
                updateNote = true
            }
            
            if updateTags && newLevelTags != note!.tags.value {
                updateNote = true
            }
            
            if updateNote {
                notesToUpdate.append(note!)
                if updateSeq {
                    updatedSeqs.append(newSeq)
                }
                if updateTags {
                    updatedTags.append(newTags)
                }
            }
            
            first = false
            (note, position) = io!.nextNote(position)
        }
        
        // Now perform the updates.
        var updateIndex = 0
        while updateIndex < notesToUpdate.count {
            let originalNote = notesToUpdate[updateIndex]
            let modNote = originalNote.copy() as! Note
            if updateSeq {
                let newSeq = updatedSeqs[updateIndex]
                _ = modNote.setSeq(newSeq)
            }
            if updateTags {
                let newTags = updatedTags[updateIndex]
                _ = modNote.setTags(newTags)
            }
            _ = noteIO.modNote(oldNote: originalNote, newNote: modNote)
            updateIndex += 1
        }
        
        // Now let the user see the results.
        finishBatchOperation()
        reloadCollection(self)
        reportNumberOfNotesUpdated(notesToUpdate.count)
    }
    
    /// If we have past due daily tasks, then update the dates to make them current
    @IBAction func menuCatchUpDailyTasks(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        
        let today = DateValue("today")
        var notesToUpdate: [Note] = []
        var (note, position) = io!.firstNote()
        crumbs!.refresh()
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
            _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        reloadViews()
        (note, position) = io!.firstNote()
        select(note: note, position: position, source: .nav)
    }
    
    /// If we have tasks that have been completed, but not closed, then close them now.
    @IBAction func closeAllCompletedTasks(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        var (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        var notesToUpdate: [Note] = []
        let config = noteIO.collection!.statusConfig
        while note != nil {
            if note!.hasStatus() {
                if note!.status.getInt() == config.doneThreshold {
                    notesToUpdate.append(note!)
                }
            }
            (note, position) = io!.nextNote(position)
        }
        for noteToUpdate in notesToUpdate {
            let modNote = noteToUpdate.copy() as! Note
            modNote.status.close(config: config)
            _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        finishBatchOperation()
        reportNumberOfNotesUpdated(notesToUpdate.count)
    }
    
    @IBAction func standardizeDatesToYMD(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        var (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        var updated = 0
        while note != nil {
            if note!.hasDate() {
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
        reportNumberOfNotesUpdated(updated)
    }
    
    /// The user has requested a chance to make mass changes to tags in  this Collection. 
    @IBAction func tagsMassChange(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        if let tagsMassChangeController = self.tagsMassChangeStoryboard.instantiateController(withIdentifier: "tagsMassChangeWC") as? TagsMassChangeWindowController {
            tagsMassChangeController.showWindow(self)
            tagsMassChangeController.passCollectionInfo(io: noteIO, collectionWC: self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Tags Mass Change Window Controller!")
        }
    }
    
    func tagsMassChangeNow(from: String, to: String, vc: TagsMassChangeViewController) {
        guard from.count > 0 else {
            vc.window!.close()
            return
        }
        guard let noteIO = guardForCollectionAction() else {
            vc.window!.close()
            return
        }
        logInfo(msg: "Changing tags from '\(from)' to '\(to)'")
        let fromTags = TagsValue(from)
        let toTags = TagsValue(to)
        
        var (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        var updated = 0
        while note != nil {
            if note!.hasTags() {
                let newTags = TagsValue()
                var matchedTags = 0
                for noteTag in note!.tags.tags {
                    var matchFound = false
                    for fromTag in fromTags.tags {
                        if fromTag == noteTag {
                            matchFound = true
                            break
                        }
                    }
                    if matchFound {
                        matchedTags += 1
                    } else {
                        newTags.tags.append(noteTag)
                    }
                }
                if matchedTags == fromTags.tags.count {
                    updated += 1
                    for toTag in toTags.tags {
                        newTags.tags.append(toTag)
                    }
                    newTags.sort()
                    let modNote = note!.copy() as! Note
                    _ = modNote.setTags(newTags.value)
                    _ = noteIO.modNote(oldNote: note!, newNote: modNote)
                }
            }
            (note, position) = noteIO.nextNote(position)
        }
        vc.window!.close()
        finishBatchOperation()
        logInfo(msg: "Notes with tags changed = \(updated)")
        reportNumberOfNotesUpdated(updated)
    }
    
    func reportNumberOfNotesUpdated(_ updated: Int) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        if updated == 0 {
            alert.messageText = "No Notes were updated"
        } else if updated == 1 {
            alert.messageText = "1 Note was updated"
        } else {
            alert.messageText = "\(updated) Notes were updated"
        }
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    /// Copy the selected note to the system clipboard.
    @IBAction func copy(_ sender: AnyObject?) {
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        let maker = NoteLineMaker()
        let _ = maker.putNote(selectedNote)
        var str = ""
        if let writer = maker.writer as? BigStringWriter {
            str = writer.bigString
        }
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    /// Copy the selected note to the system clipboard and then
    /// attempt to delete the note.
    @IBAction func cut(_ sender: AnyObject?) {
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        let maker = NoteLineMaker()
        let _ = maker.putNote(selectedNote)
        var str = ""
        if let writer = maker.writer as? BigStringWriter {
            str = writer.bigString
        }
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
        if str.count > 0 {
            deleteNote(sender ?? self)
        }
    }
    
    /// Paste the passed notes found in the system clipboard.
    @IBAction func paste(_ sender: AnyObject?) {
        let board = NSPasteboard.general
        guard let items = board.pasteboardItems else { return }
        _ = pasteItems(items, row: -1, dropOperation: .above)
    } // end of paste function
    
    /// Paste incoming items, whether via drag or paste, returning number of notes added.
    func pasteItems(_ pbItems: [NSPasteboardItem], row: Int, dropOperation: NSTableView.DropOperation) -> Int{
        
        // Make sure we're ready to do stuff.
        guard let noteIO = guardForCollectionAction() else { return 0 }
        guard let collection = noteIO.collection else { return 0 }
        
        // Initialize constants and variables.
        var notesAdded = 0
        var firstNotePasted: Note?
        let urlNameType = NSPasteboard.PasteboardType("public.url-name")
        let urlType     = NSPasteboard.PasteboardType("public.url")
        let fileURLType = NSPasteboard.PasteboardType("public.file-url")
        let vcardType   = NSPasteboard.PasteboardType(kUTTypeVCard as String)
        // let utf8Type    = NSPasteboard.PasteboardType("public.utf8-plain-text")
        
        // Process each pasteboard item.
        for item in pbItems {
            var str = item.string(forType: .string)
            if str != nil {
                str = StringUtils.trim(str!)
            }
            let vcard = item.string(forType: vcardType)
            let url = item.string(forType: urlType)
            let title = item.string(forType: urlNameType)
            let fileRefURL = item.string(forType: fileURLType)
            
            // let utf8 = item.string(forType: utf8Type)
            
            let note = Note(collection: collection)
            
            if url != nil && title != nil {
                logInfo(msg: "Processing pasted item as URL: \(title!)")
                _ = note.setTitle(title!)
                _ = note.setLink(url!)
            } else if vcard != nil {
                logInfo(msg: "Processing pasted item as VCard")
                let parser = VCardParser()
                let cards = parser.parse(vcard!)
                for vcard in cards {
                    let contactNote = NoteFromVCard.makeNote(from: vcard, collection: collection)
                    let addedNote = addPastedNote(contactNote)
                    if addedNote != nil {
                        notesAdded += 1
                        if firstNotePasted == nil {
                            firstNotePasted = addedNote
                        }
                    }
                }
            } else if fileRefURL != nil {
                logInfo(msg: "Processing pasted item as File Ref URL")
                let fileURL = URL(fileURLWithPath: fileRefURL!).standardized
                if row >= 0 && dropOperation == .on {
                    let dropNote = noteIO.getNote(at: row)
                    if dropNote != nil {
                        select(note: dropNote, position: nil, source: .action)
                        addAttachment(urlToAttach: fileURL)
                        if firstNotePasted == nil {
                            firstNotePasted = dropNote
                        }
                    }
                }
            // } else if utf8 != nil && utf8!.count > 0 {
            //     print("    - utf8: \(utf8!)")
            } else if str != nil && str!.count > 0 {
                logInfo(msg: "Processing pasted item as Note")
                let tempCollection = NoteCollection()
                tempCollection.otherFields = true
                let reader = BigStringReader(str!)
                let parser = NoteLineParser(collection: tempCollection, reader: reader)
                let tempNote = parser.getNote(defaultTitle: "Pasted Note Number \(notesAdded)",
                    allowDictAdds: true)
                if !tempNote.title.value.hasPrefix("Pasted Note Number ")
                        || tempNote.hasBody() || tempNote.hasLink() {
                    tempNote.copyDefinedFields(to: note)
                }
            } else {
                logInfo(msg: "Not sure how to handle this pasted item")
            }
            let addedNote = addPastedNote(note)
            if addedNote != nil {
                notesAdded += 1
                if firstNotePasted == nil {
                    firstNotePasted = addedNote
                }
            }
        } // end for each item
        finishBatchOperation()
        if firstNotePasted != nil {
            select(note: firstNotePasted, position: nil, source: .nav)
        }
        return notesAdded
    }
    
    /// Queue used for reading and writing file promises.
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    /// Directory URL used for accepting file promises.
    private lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
    func pastePromises(_ promises: [Any]) {
        emailPromised = false
        for item in promises {
            let promise = item as? NSFilePromiseReceiver
            if promise != nil {
                pendingPromise = true
                for fileType in promise!.fileTypes {
                    if fileType == "eml" {
                        emailPromised = true
                    }
                }
                promise!.receivePromisedFiles(atDestination: self.destinationURL,
                                              options: [:],
                                              operationQueue: self.workQueue) { (fileURL, error) in
                    if let error = error {
                        self.handlePromiseError(error)
                    } else {
                        self.handlePromisedFile(at: fileURL)
                    }
                }
            } // end for each good promise
        } // end for each promise
    } // end func pastePromises
    
    func handlePromiseError(_ error: Error) {
        OperationQueue.main.addOperation {
            self.communicateError("Error fulfilling a file promise: \(error)")
            /* if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
            self.imageCanvas.isLoading = false */
        }
    }
    
    func handlePromisedFile(at url: URL) {
        var str = ""
        do {
            str = try String(contentsOf: url, encoding: .utf8)
            if emailPromised {
                scanPromisedEmailFile(str: str)
            }
        } catch {
            communicateError("Error trying to read contents of file at \(url.path)")
        }
    }
    
    func scanPromisedEmailFile(str: String) {
        guard !pendingMod else { return }
        guard io != nil && io!.collectionOpen else { return }
        guard let noteIO = io else { return }
        guard let collection = noteIO.collection else { return }
        let msg = EmailMessage()
        msg.scan(str: str)
        if msg.subject.count > 0 {
            let note = Note(collection: collection)
            _ = note.setTitle(msg.subject)
            var body = ""
            if msg.to.count > 0 {
                body.append("To: \(msg.to)  \n")
            }
            if msg.from.count > 0 {
                body.append("From: \(msg.from)  \n")
            }
            if msg.date.count > 0 {
                body.append("Date: \(msg.date)  \n")
            }
            if msg.body.count > 0 {
                body.append(msg.body)
            }
            if body.count > 0 {
                _ = note.setBody(body)
            }
            _ = addPastedNote(note)
        }
    }
    
    func addNewNote(_ noteToAdd: Note) -> Note? {
        let addedNote = addPastedNote(noteToAdd)
        finishBatchOperation()
        if addedNote != nil {
            select(note: addedNote, position: nil, source: .action)
        }
        return addedNote
    }
    
    func addPastedNote(_ noteToAdd: Note) -> Note? {
        guard !pendingMod else { return nil }
        guard io != nil && io!.collectionOpen else { return nil }
        guard let noteIO = io else { return nil }
        guard noteToAdd.hasTitle() else { return nil }
        let originalTitle = noteToAdd.title.value
        var keyFound = true
        var dupCount = 1
        while keyFound {
            let id = noteToAdd.noteID
            let existingNote = noteIO.getNote(forID: id)
            if existingNote != nil {
                dupCount += 1
                _ = noteToAdd.setTitle("\(originalTitle) \(dupCount)")
                keyFound = true
            } else {
                keyFound = false
            }
        }
        let (pastedNote, _) = noteIO.addNote(newNote: noteToAdd)
        return pastedNote
    }
    
    /// Ask the user to pick a file or folder and set the link field to the local URL
    @IBAction func setLocalLink(_ sender: Any) {

        // See if we have what we need to proceed
        guard !pendingMod else { return }
        guard io != nil && io!.collectionOpen else { return }
        guard let noteIO = io else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let selNote = note else { return }
        guard noteIO.collection!.dict.contains(NotenikConstants.link) else { return }

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
                communicateError("Attempt to set link value for selected note failed!")
            }
            editVC!.populateFields(with: selNote)
            let writeOK = noteIO.writeNote(selNote)
            if !writeOK {
                communicateError("Attempted write of updated note failed!")
            }
            displayModifiedNote(updatedNote: selNote)
            reloadViews()
            select(note: selNote, position: nil, source: .action)
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    @IBAction func menuNoteClose(_ sender: Any) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, _) = io!.getSelectedNote()
        guard note != nil else { return }
        
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.closeNote()
        } else {
            let modNote = note!.copy() as! Note
            modNote.close()
            let (_, _) = io!.deleteSelectedNote(preserveAttachments: true)
            let (addedNote, _) = io!.addNote(newNote: modNote)
            if addedNote == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Problems adding note titled \(modNote.title)")
            } else {
                displayModifiedNote(updatedNote: addedNote!)
                reloadViews()
                select(note: addedNote, position: nil, source: .action)
            }
        }
    }
    
    ///   either the Seq field or the Date field
    @IBAction func menuNoteIncrement(_ sender: Any) {
        
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        incrementNote(selNote)
    }
    
    func incrementNote(_ selNote: Note) {
        guard let noteIO = guardForCollectionAction() else { return }
        let modNote = selNote.copy() as! Note
        let sortParm = noteIO.collection!.sortParm
        
        // Determine which field to increment
        if !selNote.hasSeq() && !selNote.hasDate() {
            return
        } else if selNote.hasSeq() && !selNote.hasDate() {
            incSeq(noteIO: noteIO, note: selNote, modNote: modNote)
        } else if selNote.hasDate() && !selNote.hasDate() {
            incrementDate(noteIO: noteIO, note: selNote, modNote: modNote)
        } else if sortParm == .seqPlusTitle || sortParm == .tasksBySeq {
            incSeq(noteIO: noteIO, note: selNote, modNote: modNote)
        } else {
            incrementDate(noteIO: noteIO, note: selNote, modNote: modNote)
        }
    }
    
    @IBAction func menuNoteToggleStatus(_ sender: Any) {
        
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        let modNote = selNote.copy() as! Note
        modNote.toggleStatus()
        let _ = recordMods(noteIO: noteIO, note: selNote, modNote: modNote)
    }
    
    @IBAction func menuNoteIncrementStatus(_ sender: Any) {
        
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        let modNote = selNote.copy() as! Note
        modNote.incrementStatus()
        let _ = recordMods(noteIO: noteIO, note: selNote, modNote: modNote)
    }
    
    /// Increment the Note's Date field by one day.
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use.
    ///   - note: The note prior to being incremented.
    ///   - modNote: A copy of the note being incremented.
    func incrementDate(noteIO: NotenikIO, note: Note, modNote: Note) {
        let incDate = SimpleDate(yr: note.date.year, mn: note.date.month, dy: note.date.day)
        if incDate.goodDate {
            incDate.addDays(1)
            let strDate = String(describing: incDate)
            let _ = modNote.setDate(strDate)
            let _ = recordMods(noteIO: noteIO, note: note, modNote: modNote)
        }
    }
    
    /// Increment the Note's Seq field by one.
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use.
    ///   - note: The note prior to being incremented.
    ///   - modNote: A copy of the note being incremented.
    func incSeq(noteIO: NotenikIO, note: Note, modNote: Note) {
        let notesInced = Sequencer.incrementSeq(io: noteIO, startingNote: note)
        logInfo(msg: "\(notesInced) Notes had their Seq values incremented")
        displayModifiedNote(updatedNote: note)
        editVC!.populateFields(with: note)
        reloadViews()
        select(note: note, position: nil, source: .action)
    }
    
    @IBAction func incMajorSeq(_ sender: Any) {
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        guard selNote.hasSeq() else { return }
        let sortParm = noteIO.collection!.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .tasksBySeq else { return }
        
        let notesInced = Sequencer.incrementSeq(io: noteIO, startingNote: selNote, incMajor: true)
        logInfo(msg: "\(notesInced) Notes had their Seq values incremented")
        displayModifiedNote(updatedNote: selNote)
        editVC!.populateFields(with: selNote)
        reloadViews()
        select(note: selNote, position: nil, source: .action)
    }
    
    /// Record modifications made to the Selected Note
    ///
    /// - Parameters:
    ///   - noteIO: The NotenikIO module to use
    ///   - note: The note that's been changed.
    ///   - modNote: The note with modifications.
    /// - Returns: True if changes were recorded successfully; false otherwise.
    func recordMods (noteIO: NotenikIO, note: Note, modNote: Note) -> Bool {
        guard noteIO.reattach(from: note, to: modNote) else { return false }
        let (_, _) = noteIO.deleteSelectedNote(preserveAttachments: true)
        let (addedNote, _) = noteIO.addNote(newNote: modNote)
        if addedNote == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .error,
                              message: "Problems adding note titled \(modNote.title)")
            return false
        } else {
            displayModifiedNote(updatedNote: addedNote!)
            // editVC!.populateFields(with: addedNote!)
            editVC!.select(note: addedNote!)
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
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        shareNote(selNote)
    }
    
    func shareNote(_ note: Note) {
        guard let noteIO = guardForCollectionAction() else { return }
        if let shareController = self.shareStoryboard.instantiateController(withIdentifier: "shareWC") as? ShareWindowController {
            guard let vc = shareController.contentViewController as? ShareViewController else { return }
            shareController.showWindow(self)
            vc.window = shareController
            vc.io = noteIO
            vc.note = note
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Share Window Controller!")
        }
    }
    
    @IBAction func menuNotePublishToMedium(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        if let mediumPubController = self.mediumPubStoryboard.instantiateController(withIdentifier: "mediumpubWC") as? MediumPubWindowController {
            mediumPubController.note = selectedNote
            mediumPubController.showWindow(sender)
            
            // vc.window = shareController
            // vc.io = notenikIO!
            // vc.note = note
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Medium Publish Window Controller!")
        }
    }
    
    @IBAction func menuNotePublishToMicroBlog(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        if let microBlogController = self.microBlogStoryboard.instantiateController(withIdentifier: "microblogWC") as? MicroBlogWindowController {
            microBlogController.note = selectedNote
            microBlogController.showWindow(sender)
            
            // vc.window = shareController
            // vc.io = notenikIO!
            // vc.note = note
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Medium Publish Window Controller!")
        }
    }
    
    /// Show the user a window displaying various counts for the body of the current Note.
    @IBAction func showCounts(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard sel != nil else { return }
        let countsVC = juggler.showCounts(sender)
        if countsVC != nil {
            if displayVC != nil {
                displayVC!.countsVC = countsVC
            }
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
            let _ = noteIO.position
        }
    }
    
    /// Go to the first note in the list
    @IBAction func goToFirstNote(_ sender: Any) {
        let (nio, _) = guardForNoteAction()
        guard let noteIO = nio else { return }
        let (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        select(note: note, position: position, source: .nav)
    }
    
    /// Go to the next note in the list
    @IBAction func goToNextNote(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        
        let nextNote = crumbs!.advance(from: selNote)

        select(note: nextNote, position: nil, source: .nav)
    }
    
    @IBAction func scrollToSelected(_ sender: Any) {
        guard listVC != nil else { return }
        listVC!.scrollToSelectedRow()
    }
    
    /// Go to the prior note in the list
    @IBAction func goToPriorNote(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        if webLinkFollowed && displayVC != nil {
            displayVC!.reload()
            return
        }
        
        let priorNote = crumbs!.backup(from: selNote)
        
        select(note: priorNote, position: nil, source: .nav)
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
        guard let noteIO = guardForCollectionAction() else { return }
        var found = false
        var (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        while !found && note != nil {
            found = searchNote(note!, for: searchFor)
            if !found {
                (note, position) = noteIO.nextNote(position)
            }
        }
        if found {
            select(note: note, position: position, source: .action, andScroll: true)
        } else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "No Note found containing search string '\(searchFor)'"
            alert.informativeText = "Searched for case-insensitve match on title, link, tags and body fields"
            
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
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
        let startingNote = note!
        let startingPosition = position
        (note, position) = noteIO.nextNote(position)
        var found = false
        while !found && note != nil {
            found = searchNote(note!, for: searchFor)
            if !found {
                (note, position) = noteIO.nextNote(position)
            }
        }
        if found {
            select(note: note, position: position, source: .action, andScroll: true)
        } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "No more notes found containing search string '\(searchFor)'"
            alert.informativeText = "Searched for case-insensitve match on title, link, tags and body fields"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            select(note: startingNote, position: startingPosition, source: .action, andScroll: true)
            _ = noteIO.selectNote(at: startingPosition.index)
        }
    }
    
    func searchNote(_ note: Note, for searchFor: String) -> Bool {
        let searchForLower = searchFor.lowercased()
        if note.title.value.lowercased().contains(searchForLower) {
            return true
        }
        if note.link.value.lowercased().contains(searchForLower) {
            return true
        }
        if note.tags.value.lowercased().contains(searchForLower) {
            return true
        }
        if note.body.value.lowercased().contains(searchForLower) {
            return true
        }
        if note.creator.value.lowercased().contains(searchForLower) {
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
    func select(note: Note?, position: NotePosition?, source: NoteSelectionSource, andScroll: Bool = false) {
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
            listVC!.selectRow(index: positionToUse!.index, andScroll: andScroll)
        }
        
        guard noteToUse != nil else { return }
        
        if displayVC != nil {
            displayVC!.display(note: noteToUse!, io: notenikIO!)
        }
        if editVC != nil {
            editVC!.select(note: noteToUse!)
        }
        adjustAttachmentsMenu(noteToUse!)
        
        if crumbs != nil {
            crumbs!.select(noteToUse!)
        }
    }
    
    /// Adjust the Attachments menu based on the attachments found in the passed note.
    func adjustAttachmentsMenu(_ note: Note) {
        
        let topItem = attachmentsMenu.item(at: 0)
        if note.attachments.count > 0 {
            topItem!.title = "files: "
        } else {
            topItem!.title = "attach..."
        }
        var i = attachmentsMenu.numberOfItems - 1
        while i > 0 {
            attachmentsMenu.removeItem(at: i)
            i -= 1
        }
        
        let addMenuItem = NSMenuItem(title: addAttachmentTitle, action: #selector(openOrAddAttachment), keyEquivalent: "")
        attachmentsMenu.addItem(addMenuItem)
        
        for attachment in note.attachments {
            let title = attachment.suffix
            let menuItem = NSMenuItem(title: title, action: #selector(openOrAddAttachment), keyEquivalent: "")
            attachmentsMenu.addItem(menuItem)
        }
    }

    /// Open an existing attachment or add a new one.
    @objc func openOrAddAttachment(_ sender: NSMenuItem) {
        
        // See if we're ready to take action
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        
        if sender.title == addAttachmentTitle {
            addAttachment()
        } else {
            let attachmentURL = selNote.getURLforAttachment(attachmentName: sender.title)
            // let attachmentURL = noteIO.getURLforAttachment(fileName: sender.title)
            
            if attachmentURL != nil {
                let goodOpen = NSWorkspace.shared.open(attachmentURL!)
                if !goodOpen {
                    communicateError("Trouble opening attachment at \(attachmentURL!.absoluteString)", alert: true)
                }
            } else {
                communicateError("Trouble opening selected attachment", alert: true)
            }
        }
        attachmentsMenu.performActionForItem(at: 0)
    }
    
    /// Prompt the user for an attachment to add and then copy it to the files folder.
    func addAttachment() {
        // Ask the user for a location on disk
        let openPanel = NSOpenPanel();
        openPanel.title = "Select an attachment for this Note"
        let parent = io!.collection!.fullPathURL!.deletingLastPathComponent()
        openPanel.directoryURL = parent
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        let response = openPanel.runModal()
        guard response == .OK else { return }
        guard let urlToAttach = openPanel.url else { return }
        addAttachment(urlToAttach: urlToAttach)
    }
    
    func addAttachment(urlToAttach: URL) {
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        guard selNote.fileInfo.base != nil else { return }
        let filesFolderResource = noteIO.collection!.lib.ensureResource(type: .attachments)
        guard filesFolderResource.isAvailable else { return }
        if let attachmentController = self.attachmentStoryboard.instantiateController(withIdentifier: "attachmentWC") as? AttachmentWindowController {
            attachmentController.vc.master = self
            attachmentController.vc.setFileToCopy(urlToAttach)
            attachmentController.vc.setStorageFolder(filesFolderResource.actualPath)
            attachmentController.vc.setNote(selNote)
            attachmentController.showWindow(self)
        } else {
            communicateError("Couldn't get an Attachment Window Controller!")
        }
    }
    
    /// The user has responded OK to proceed with adding an attachment.
    ///
    /// - Parameters:
    ///   - note: The note to which the attachment should be added.
    ///   - file: A URL pointing to the file to become attached.
    ///   - suffix: The unique identifier for this particular attachment to this note.
    ///
    func okToAddAttachment(note: Note, file: URL, suffix: String) {
        guard let noteIO = guardForCollectionAction() else { return }
        let added = noteIO.addAttachment(from: file, to: note, with: suffix)
        if added {
            adjustAttachmentsMenu(note)
            if let imageDef = noteIO.collection?.imageNameFieldDef {
                let imageField = note.getField(def: imageDef)
                if imageField == nil || imageField!.value.value.count == 0 {
                    let ext = file.pathExtension
                    switch ext {
                    case "gif", "jpg", "jpeg", "png":
                        _ = note.setField(label: imageDef.fieldLabel.commonForm, value: suffix)
                        _ = noteIO.writeNote(note)
                        displayModifiedNote(updatedNote: note)
                        editVC!.populateFields(with: note)
                        reloadViews()
                    default:
                        break
                    }
                }
                
                
            }
            
        } else {
            communicateError("Attachment could not be added - possible duplicate", alert: true)
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
            incSeq.increment()
            _ = newNote!.setSeq(incSeq.value)
        }
        
        if selection != nil && selection!.hasLevel() {
            _ = newNote!.setLevel(selection!.level.value)
        }
        
        editVC!.populateFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    /// Duplicate the Selected Note
    @IBAction func duplicateNote(_ sender: Any) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        let (selectedNote, _) = notenikIO!.getSelectedNote()
        guard selectedNote != nil else { return }
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        duplicateNote(startingNote: selectedNote!)
    }
    
    /// Duplicate the passed Note. 
    func duplicateNote(startingNote: Note) {
        guard let noteIO = guardForCollectionAction() else { return }
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        editVC!.populateFields(with: startingNote)
        noteTabs!.tabView.selectLastTabViewItem(self)
    }
    
    /// Delete the Note
    @IBAction func deleteNote(_ sender: Any) {
        
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selectedNote = sel else { return }
        
        if noteIO.notesCount < 2 {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "A Notenik Collection always needs to have at least one Note"
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
            return
        }
        
        var proceed = true
        if appPrefs.confirmDeletes {
            let alert = NSAlert()
            alert.alertStyle = .warning
            var attachMsg = ""
            if selectedNote.attachments.count > 0 {
                attachMsg = " and its \(selectedNote.attachments.count) attachment"
                if selectedNote.attachments.count > 1 {
                    attachMsg.append("s")
                }
            }
            alert.messageText = "Really delete the Note titled '\(selectedNote.title)'\(attachMsg)?"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                proceed = false
            }
        }
        if proceed {
            pendingEdits = false
            let (nextNote, nextPosition) = noteIO.deleteSelectedNote(preserveAttachments: false)
            reloadViews()
            if nextNote != nil {
                select(note: nextNote, position: nextPosition, source: .action)
            }
        }
    }
    
    func checkForPromises() {
        if pendingPromise {
            reloadViews()
        }
    }
    
    /// Reload the Collection Views when data has changed
    func reloadViews() {
        listVC!.reload()
        tagsVC!.reload()
        pendingPromise = false
    }
    
    @IBAction func discardEdits(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        if newNoteRequested {
            let (note, position) = io!.firstNote()
            crumbs!.refresh()
            select(note: note, position: position, source: .action)
        } else {
            let (note, _) = io!.getSelectedNote()
            guard note != nil else { return }
            select(note: note, position: nil, source: .action)
        }
        newNoteRequested = false
        pendingMod = false
        
        noteTabs!.tabView.selectFirstTabViewItem(nil)
    }
    
    @IBAction func openEdits(_ sender: Any) {
        guard noteTabs!.tabView.selectedTabViewItem!.label != "Edit"  else { return }
        let (_, sel) = guardForNoteAction()
        guard sel != nil else { return }
        noteTabs!.tabView.selectTabViewItem(at: 1)
    }
    
    @IBAction func saveEdits(_ sender: Any) {
        if !pendingMod {
            let _ = modIfChanged()
        }
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    func modIfChanged() -> modIfChangedOutcome {
        guard editVC != nil else { return .notReady }
        guard !pendingMod else {
            checkForPromises()
            return .notReady
        }
        guard newNoteRequested || pendingEdits else {
            checkForPromises()
            return .noChange
        }
        pendingMod = true
        let (outcome, note) = editVC!.modIfChanged(newNoteRequested: newNoteRequested, newNote: newNote)
        if outcome != .tryAgain {
            newNoteRequested = false
        }
        if outcome != .tryAgain && outcome != .noChange {
            pendingEdits = false
        }
        if outcome == .add || outcome == .deleteAndAdd || outcome == .modify {
            editVC!.populateFields(with: note!)
        }
        if outcome == .add || outcome == .deleteAndAdd {
            reloadViews()
            select(note: note, position: nil, source: .action)
            if note != nil {
                mirrorNote(note!)
            }
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome == .modify {
            displayModifiedNote(updatedNote: note!)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome != .tryAgain {
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        }
        pendingMod = false
        if outcome == .add || outcome == .deleteAndAdd || outcome == .modify {
            checkForReviewRequest()
        }
        checkForPromises()
        return outcome
    }
    
    /// Update outputs showing the data from the updated note.
    func displayModifiedNote(updatedNote: Note) {
        if displayVC != nil {
            displayVC!.display(note: updatedNote, io: notenikIO!)
        }
        if updatedNote.collection.mirror != nil {
            mirrorNote(updatedNote)
        }
    }
    
    /// See if this is an appropriate time to ask the user for an app store review
    func checkForReviewRequest() {
        if #available(OSX 10.14, *) {
            if appPrefs.newVersionForReview {
                appPrefs.incrementUseCount()
                if appPrefs.useCount > 20 {
                    appPrefs.userPromptedForReview()
                    SKStoreReviewController.requestReview()
                }
            }
        }
    }
    
    @IBAction func saveDocumentAs(_ sender: NSMenuItem) {
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        guard let window = self.window as? CollectionWindow else { return }
        juggler.userRequestsSaveAs(currentIO: io!, currentWindow: window)
    }
    
    @IBAction func moveCollection(_ sender: NSMenuItem) {
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        guard let window = self.window as? CollectionWindow else { return }
        juggler.userRequestsMove(currentIO: io!, currentWindow: window)
    }
    
    @IBAction func makeCollectionEssential(_ sender: Any) {
        juggler.makeCollectionEssential(io: notenikIO!)
    }
    
    @IBAction func normalizeCollection(_ sender: Any) {
        reloadCollection(sender)
        guard let noteIO = guardForCollectionAction() else { return }
        var updated = 0
        var (note, position) = noteIO.firstNote()
        crumbs!.refresh()
        while note != nil {
            let written = noteIO.writeNote(note!)
            if written {
                updated += 1
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .error,
                                  message: "Problems saving note titled \(note!.title)")
            }
            (note, position) = noteIO.nextNote(position)
        }
        finishBatchOperation()
        reportNumberOfNotesUpdated(updated)
    }
    
    @IBAction func textEditTemplate(_ sender: Any) {
        guard let nnkIO = guardForCollectionAction() else { return }
        let templatePath = nnkIO.collection!.lib.getPath(type: .template)
        NSWorkspace.shared.openFile(templatePath)
    }
    
    /// Reload the current collection from disk
    @IBAction func reloadCollection(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let path = noteIO.collection!.fullPath
        let readOnly = noteIO.collection!.readOnly
        noteIO.closeCollection()
        newNoteRequested = false
        pendingMod = false
        pendingEdits = false
        let newIO: NotenikIO = FileIO()
        let realm = newIO.getDefaultRealm()
        realm.path = ""
        let _ = newIO.openCollection(realm: realm, collectionPath: path, readOnly: readOnly)
        self.io = newIO
    }
    
    /// Open the current Note in the user's preferred text editor.
    @IBAction func textEditNote(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let noteToUse = sel else { return }
        if !noteToUse.fileInfo.isEmpty {
            NSWorkspace.shared.openFile(noteToUse.fileInfo.fullPath!)
        }
    }
    
    /// Reload the currently selected note from disk.
    @IBAction func reloadNote(_ sender: Any) {
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        guard let reloaded = noteIO.reloadNote(selNote) else { return }
        reloadViews()
        select(note: reloaded, position: nil, source: .action)
    }
    
    /// Launch a Note's Link
    @IBAction func launchLink(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let noteToUse = sel else { return }
        launchLink(for: noteToUse)
    }
    
    func launchLinks(_ collector: NoteCollector) {
        for note in collector.notes {
            launchLink(for: note)
        }
    }
    
    func launchLink(for noteToUse: Note) {
        var possibleURL = noteToUse.linkAsURL
        if possibleURL == nil {
            possibleURL = noteToUse.firstLinkAsURL
        }
        guard let url = possibleURL else { return }
        launchLink(url: url)
    }
    
    /// Attempt to launch the passed URL.
    func launchLink(url: URL) {
        let link = NotenikLink(url: url)
        if link.type == .script {
            launchScript(fileURL: url)
            return
        } else if link.type == .folder {
            link.determineCollectionType()
            if link.type == .ordinaryCollection || link.type == .webCollection {
                let _ = juggler.openFileWithNewWindow(fileURL: url, readOnly: false)
                return
            }
        }
        
        let ok = NSWorkspace.shared.open(url)
        if !ok {
            communicateError("Could not open the requested url: \(url.absoluteString)", alert: true)
        }
    }
    
    func launchScript(fileURL: URL) {
        juggler.launchScript(fileURL: fileURL)
    }
    
    @IBAction func reloadDisplayView(_ sender: Any) {
        guard displayVC != nil else { return }
        displayVC!.reload()
        checkForPromises()
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
    
    @IBAction func sortByTagsAndTitle(_ sender: Any) {
        setSortParm(.tagsPlusTitle)
    }
    
    @IBAction func sortByTagsAndSeq(_ sender: Any) {
        setSortParm(.tagsPlusSeq)
    }
    
    @IBAction func sortByAuthor(_ sender: Any) {
        setSortParm(.author)
    }
    
    @IBAction func sortByDateAdded(_ sender: Any) {
        setSortParm(.dateAdded)
    }
    
    @IBAction func sortReverse(_ sender: NSMenuItem) {
        guard let io = notenikIO else { return }
        if io.sortDescending {
            setSortDescending(false)
        } else {
            setSortDescending(true)
        }
    }
    
    func setSortParm(_ sortParm: NoteSortParm) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortParm = sortParm
        lister.setSortParm(sortParm)
        noteIO.persistCollectionInfo()
    }
    
    func setSortDescending(_ descending: Bool) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortDescending = descending
        lister.setSortDescending(descending)
        noteIO.persistCollectionInfo()
    }
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code contains xmlimport, export and archive routines.
    //
    // ----------------------------------------------------------------------------------
    
    
    /// Purge closed Notes from this Collection
    @IBAction func userRequestsPurge(_ sender: Any) {
        
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        // Make sure we have a status field for this collection
        let dict = noteIO.collection!.dict
        if !dict.contains(NotenikConstants.status) {
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
                          message: "\(purgeCount) Notes purged from Collection at \(io!.collection!.fullPath)")
        reloadViews()
        let (note, position) = io!.firstNote()
        crumbs!.refresh()
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
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input tab- or comma-separated text file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        importDelimitedFromURL(importURL, noteIO: noteIO)
    }
    
    func importDelimitedFromURL(_ fileURL: URL, noteIO: NotenikIO) {
        let importer = DelimitedReader()
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importCSVfromOmniFocus(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open a CSV file from OmniFocus",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        importCSVfromOmniFocus(importURL, noteIO: noteIO)
    }
    
    func importCSVfromOmniFocus(_ fileURL: URL, noteIO: NotenikIO) {
        let importer = OmniFocusReader()
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importPlainTextfromOmniFocus(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open a Plain Text file from OmniFocus",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        importPlainTextfromOmniFocus(importURL, noteIO: noteIO)
    }
    
    func importPlainTextfromOmniFocus(_ fileURL: URL, noteIO: NotenikIO) {
        let importer = OmniFocusPlainTextReader()
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importXLSX(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input XLSX file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        importXSLXFromURL(importURL)
    }
    
    func importXSLXFromURL(_ fileURL: URL) {
        guard let noteIO = guardForCollectionAction() else { return }
        let importer = XLSXReader()
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
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
        let importCollection = importIO.openCollection(realm: importRealm, collectionPath: importURL.path, readOnly: true)
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
        
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importXML(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input XML file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }

        let importer = XMLNoteImporter(io: noteIO)
        let imports = importer.importFrom(importURL)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes from \(importURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes from \(importURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    /// Prompt the user for the location of a file to import.
    func promptUserForImportFile(title: String, parent: URL?) -> URL? {
        let openPanel = NSOpenPanel();
        openPanel.title = title
        openPanel.directoryURL = parent
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return nil }
        guard let importURL = openPanel.url else { return nil }
        return importURL
    }
    
    @IBAction func favoritesToHTML(_ sender: Any) {
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        guard let fileURL = getExportURL(fileExt: "html", fileName: "favorites") else { return }
        let favsToHTML = FavoritesToHTML(noteIO: noteIO, outURL: fileURL)
        let genOK = favsToHTML.generate()
        if genOK {
            NSWorkspace.shared.open(fileURL)
        }
    }
    
    /// Ask the user where to save the export file
    func getExportURL(fileExt: String, fileName: String = "export") -> URL? {
        guard io != nil && io!.collectionOpen else { return nil }
        
        let outcome = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return nil }
        
        let savePanel = NSSavePanel();
        savePanel.title = "Specify an output file"
        let parent = io!.collection!.fullPathURL
        savePanel.directoryURL = parent
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
    
    /// Export the current collection in Notenik format.
    @IBAction func oldExportNotenik(_ sender: Any) {
        
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        let collectionURL = noteIO.collection!.fullPathURL
        
        let openPanel = juggler.prepCollectionOpenPanel()
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }
        
        let exportURL = openPanel.url!
        
        var ok = true
        var numberOfNotes = 0
        do {
            try FileManager.default.removeItem(at: exportURL)
            try FileManager.default.copyItem(at: collectionURL!, to: exportURL)
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
    // The following functions support note transformation via mirroring, reports. etc.
    //
    // ----------------------------------------------------------------------------------
    
    @IBAction func stashNotesInSubfolder(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard !collection.lib.hasAvailable(type: .notesSubfolder) else {
            communicateError("This collection is already stashed in a subfolder",
                             alert: true)
            return
        }
        guard let window = self.window as? CollectionWindow else { return }
        _ = juggler.stashNotesInSubfolder(currentIO: noteIO, currentWindow: window)
    }
    
    @IBAction func genMirrorSample(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard collection.mirror == nil else {
            communicateError("This Collection already has a functioning mirror folder",
                             alert: true)
            return
        }
        collection.mirror = NoteTransformer.genSampleMirrorFolder(io: noteIO)
        if collection.mirror == nil {
            communicateError("Problems encountered trying to generate sample mirror folder",
                             alert: true)
        } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Sample Mirror Folder Created"
            alert.informativeText = "Feel free to use your favorite text editor to modify the contents of the mirror folder to suit your particular needs. "
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }
    }
    
    /// Launch a task to mirror all notes in the collection.
    @IBAction func mirrorNotes(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard collection.mirror != nil else {
            communicateError("Mirror All Notes Requested but a functioning mirror folder was not found",
                             alert: true)
            return
        }
        
        mirrorAll(collection: collection)
    }
    
    @IBAction func mirrorIndices(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard collection.mirror != nil else {
            communicateError("Mirror All Indices Requested but a functioning mirror folder was not found",
                             alert: true)
            return
        }
        
        indexAll(collection: collection)
    }
    
    /// Attempt to launch a top-level index.html file in the user's web browser.
    @IBAction func browseWebIndex(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let indexURL = noteIO.collection!.fullPathURL!.appendingPathComponent(NotenikConstants.indexFileName)
        let ok = NSWorkspace.shared.open(indexURL)
        if !ok {
            communicateError("File at \(indexURL.path) could not be launched in your web browser", alert: true)
        }
    }
    
    @IBAction func mirrorAllNotesAndIndex(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard collection.mirror != nil else {
            communicateError("Mirror All Notes and Indices Requested but a functioning mirror folder was not found",
                             alert: true)
            return
        }
        
        mirrorAll(collection: collection)
        indexAll(collection: collection)
    }
    
    func mirrorAll(collection: NoteCollection) {
        let mirror = collection.mirror!
        let dispatchQ = mirror.dispatchQueue
        
        dispatchQ.async { [weak self] in
            let errors = mirror.mirrorAllNotes()
            DispatchQueue.main.async { [weak self] in
                self?.reportErrors(errors)
                if errors.count == 0 {
                    self?.logInfo(msg: "Mirroring of All Notes Completed Successfully")
                }
            }
        }
    }
    
    func indexAll(collection: NoteCollection) {
        let mirror = collection.mirror!
        let dispatchQ = mirror.dispatchQueue
        
        dispatchQ.async { [weak self] in
            let errors = mirror.rebuildIndices()
            DispatchQueue.main.async { [weak self] in
                self?.reportErrors(errors)
                if errors.count == 0 {
                    self?.logInfo(msg: "Mirror Indices of All Notes Rebuilt Successfully")
                }
            }
        }
    }
    
    /// Launch a task to mirror a single note in the collection.
    func mirrorNote(_ noteToMirror: Note) {
        let collection = noteToMirror.collection
        guard let mirror = collection.mirror else { return }
        let dispatchQ = mirror.dispatchQueue
        
        dispatchQ.async { [weak self] in
            let errors = mirror.mirror(note: noteToMirror)
            DispatchQueue.main.async { [weak self] in
                self?.reportErrors(errors)
            }
        }
        
        if collection.mirrorAutoIndex {
            dispatchQ.async { [weak self] in
                let errors = mirror.rebuildIndices()
                DispatchQueue.main.async { [weak self] in
                    self?.reportErrors(errors)
                }
            }
        }
    }
    
    /// Set up the Reports Action Menu in the Toolbar.
    func buildReportsActionMenu() {
        
        // Clear out whatever we had before
        var i = actionMenu.numberOfItems - 1
        while i > 0 {
            actionMenu.removeItem(at: i)
            i -= 1
        }
        
        guard !notenikIO!.collection!.readOnly else { return }

        var genMD = true
        var genHTML = true
        
        for report in notenikIO!.reports {
            let title = String(describing: report)
            let reportItem = NSMenuItem(title: title, action: #selector(runReport), keyEquivalent: "")
            actionMenu.addItem(reportItem)
            if report.reportName == NoteTransformer.sampleReportTemplateFileName {
                if report.reportType == "html" {
                    genHTML = false
                } else if report.reportType == "md" {
                    genMD = false
                }
            }
        }
        
        if genHTML {
            let genSampleHTML = NSMenuItem(title: "Generate Report Sample in HTML", action: #selector(genReportTemplateSample), keyEquivalent: "")
            actionMenu.addItem(genSampleHTML)
        }
        
        if genMD {
            let genSampleMD = NSMenuItem(title: "Generate Report Sample in Markdown", action: #selector(genReportTemplateSample), keyEquivalent: "")
            actionMenu.addItem(genSampleMD)
        }
    }
    
    /// Generate a sample report template.
    /// - Parameter sender: The menu item selected by the user.
    @objc func genReportTemplateSample(_ sender: NSMenuItem) {
        guard let io = guardForCollectionAction() else { return }
        // guard let reportsFolder = io.reportsFullPath else { return }
        let menuItemTitle = sender.title.lowercased()
        let markdown = menuItemTitle.contains("markdown")
        let errors = NoteTransformer.genReportTemplateSample(io: io, markdown: markdown)
        reportErrors(errors)
        
        // Now let's rebuild the reports action menu, taking the new report into consideration.
        if errors.count == 0 {
            io.loadReports()
            buildReportsActionMenu()
        }
        
        // Let the user know that we created the file.
        var runNow = false
        let sampleURL = NoteTransformer.getReportTemplateSampleURL(io: io, markdown: markdown)
        if errors.count == 0 {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Sample Report Template Created at \(sampleURL!.path)"
            alert.informativeText = "Report template file created. \n\nFeel free to rename and edit it to suit your particular needs."
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Run It Now")
            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                runNow = true
            }
        }
        
        if runNow {
            _ = runReportWithTemplate(sampleURL!)
        }
    }
    
    @objc func runReport(_ sender: NSMenuItem) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        
        var found = false
        var i = 0
        while i < noteIO.reports.count && !found {
            let report = noteIO.reports[i]
            let reportTitle = String(describing: report)
            found = (sender.title == reportTitle)
            if found {
                if report.reportType == "tcz" {
                    if noteIO.collection!.lib.hasAvailable(type: .reports) {
                        let scriptURL = noteIO.reports[i].getURL(folderPath: noteIO.collection!.lib.getPath(type: .reports))
                        if scriptURL != nil {
                            launchScript(fileURL: scriptURL!)
                        }
                    }
                } else {
                    if noteIO.collection!.lib.hasAvailable(type: .reports) {
                        let templateURL = noteIO.reports[i].getURL(folderPath: noteIO.collection!.lib.getPath(type: .reports))
                        _ = runReportWithTemplate(templateURL!)
                    }
                }
            } else {
                i += 1
            }
        }
    }
    
    /// Generate and display a report created from a template file.
    func runReportWithTemplate(_ templateURL: URL) -> Bool {
        guard let io = notenikIO else { return false }
        guard let collection = io.collection else { return false }
        let template = Template()
        var ok = template.openTemplate(templateURL: templateURL)
        if ok {
            template.supplyData(notesList: io.notesList,
                                dataSource: collection.fullPath)
            ok = template.generateOutput()
            if ok {
                let textOutURL = template.util.textOutURL
                if textOutURL != nil {
                    NSWorkspace.shared.open(textOutURL!)
                }
            } else {
                communicateError("Problems generating template output", alert: true)
            }
        } else {
            communicateError("Problems opening template file", alert: true)
        }
        return ok
    }
    
    @IBAction func genDisplaySample(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let sampler = NoteDisplaySample()
        let ok = sampler.genSampleFiles(io: noteIO)
        if ok {
            communicateSuccess("Sample Display Template Successfully Generated",
                               info: "Edit \(ResourceFileSys.displayHTMLFileName)"
                               + " and \(ResourceFileSys.displayCSSFileName)"
                               + " files as needed",
                               alert: true)
        } else {
            communicateError("Sample Display Template and CSS files could not be created")
        }
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
    
    /// Communicate success to the user.
    /// - Parameters:
    ///   - msg: The primary message to be delivered.
    ///   - info: Optional additional informative text.
    ///   - alert: Generate an alert in addition to a log message?
    func communicateSuccess(_ msg: String, info: String? = nil, alert: Bool=false) {
        if alert {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = msg
            if info != nil && info!.count > 0 {
                alert.informativeText = info!
            }
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: msg)
        if info != nil && info!.count > 0 {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .info,
                              message: info!)
        }
    }
    
    /// Send an informational message to the log. 
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: msg)
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
    
    /// Report a bunch of errors.
    func reportErrors(_ errors: [LogEvent]) {
        for error in errors {
            Logger.shared.log(error)
        }
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
    
    /// Finish up batch operations by reloading the lists and selecting the first note
    func finishBatchOperation() {
        reloadViews()
        let (note, position) = io!.firstNote()
        crumbs!.refresh()
        select(note: note, position: position, source: .nav)
    }
}

//
//  CollectionWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import StoreKit

import NotenikUtils
import NotenikLib

import ZipArchive

/// Controls a window showing a particular Collection of Notes.
class CollectionWindowController: NSWindowController, NSWindowDelegate, AttachmentMasterController, NSFilePresenter {
    
    let collectionViewID = "window-controller"
    
    let minimumWindowWidth: CGFloat = 550.0
    
    @IBOutlet var shareButton: NSButton!
    
    @IBOutlet var searchField: NSSearchField!
    
    var searcher: SearchNotes!
    
    /// The Reports Action Menu.
    @IBOutlet var actionMenu: NSMenu!
    
    @IBOutlet var attachmentsMenu: NSMenu!
    
    let application     = NSApplication.shared
    let juggler         = CollectionJuggler.shared
    let appPrefs        = AppPrefs.shared
    let displayPrefs    = DisplayPrefs.shared
    let osdir           = OpenSaveDirectory.shared
    let multi           = MultiFileIO.shared
    
    let filesTitle = "files..."
    let addAttachmentTitle = "Add Attachment..."
    
    var notenikIO:          NotenikIO?
    var preferredExt        = ""
    var backLinksDef:       FieldDefinition?
    var noteFileFormat:     NoteFileFormat = .notenik
    var hashtagsOption:     HashtagsOption = .notenikField
    var defsRemoved         = DefsRemoved()
    
    var viewCoordinator:    CollectionViewCoordinator!
    // var navHistory:         NavHistory?
    
    var webLinkFollowed     = false
    var windowNumber        = 0
    var undoMgr:            UndoManager?
    
    let collectionPrefsStoryboard: NSStoryboard = NSStoryboard(name: "CollectionPrefs", bundle: nil)
    let idPrefsStoryboard:         NSStoryboard = NSStoryboard(name: "IdPrefs", bundle: nil)
    let shareStoryboard:           NSStoryboard = NSStoryboard(name: "Share", bundle: nil)
    let mediumPubStoryboard:       NSStoryboard = NSStoryboard(name: "MediumPub", bundle: nil)
    let microBlogStoryboard:       NSStoryboard = NSStoryboard(name: "MicroBlog", bundle: nil)
    let exportStoryboard:          NSStoryboard = NSStoryboard(name: "Export", bundle: nil)
    let importStoryboard:          NSStoryboard = NSStoryboard(name: "Import", bundle: nil)
    let attachmentStoryboard:      NSStoryboard = NSStoryboard(name: "Attachment", bundle: nil)
    let tagsMassChangeStoryboard:  NSStoryboard = NSStoryboard(name: "TagsMassChange", bundle: nil)
    let advSearchStoryboard:       NSStoryboard = NSStoryboard(name: "AdvSearch", bundle: nil)
    let newWithOptionsStoryboard:  NSStoryboard = NSStoryboard(name: "NewWithOptions", bundle: nil)
    let seqModStoryboard:          NSStoryboard = NSStoryboard(name: "SeqMod", bundle: nil)
    let linkCleanerStoryboard:     NSStoryboard = NSStoryboard(name: "LinkCleaner", bundle: nil)
    let notePickerStoryboard:      NSStoryboard = NSStoryboard(name: "NotePicker", bundle: nil)
    let dateInsertStoryboard:      NSStoryboard = NSStoryboard(name: "DateInsert", bundle: nil)
    let queryBuilderStoryboard:    NSStoryboard = NSStoryboard(name: "QueryBuilder", bundle: nil)
    let tagsAssignStoryboard:      NSStoryboard = NSStoryboard(name: "TagsAssign", bundle: nil)
    let fieldRenameStoryboard:     NSStoryboard = NSStoryboard(name: "FieldRename", bundle: nil)
    let bulkEditStoryboard:        NSStoryboard = NSStoryboard(name: "BulkEdit", bundle: nil)
    let seqOutlineStoryboard:      NSStoryboard = NSStoryboard(name: "SeqOutline", bundle: nil)
    let wikiQuoteStoryboard:       NSStoryboard = NSStoryboard(name: "WikiQuote", bundle: nil)
    
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
                    var seqOutlineVC: SeqOutlineViewController?

        var noteItem: NSSplitViewItem?
            var noteTabs: NoteTabsViewController?
                var displayItem: NSTabViewItem?
                    var displayVC: NoteDisplayViewController?
                var editItem: NSTabViewItem?
                    var editVC: NoteEditViewController?
    
    var viewsCoordinator: CollectionViewCoordinator!
    
    var scroller: NoteScroller?
    
    var reportRunner: ReportRunner?
    
    var io: NotenikIO? {
        get {
            return notenikIO
        }
        set {
            notenikIO = newValue
            juggler.setLastSelection(title: "", link: "", filepath: "", wc: nil)
            guard notenikIO != nil && notenikIO!.collection != nil else {
                window!.title = "No Collection to Display"
                return
            }
            
            searcher = SearchNotes(io: newValue!)
            // navHistory = NavHistory(io: newValue!)
            viewCoordinator.notenikIO = newValue!
            
            window!.representedURL = notenikIO!.collection!.fullPathURL
            startFileCoordination()
            if notenikIO!.collection!.title == "" {
                notenikIO!.collection!.setDefaultTitle()
            }
            if notenikIO!.collection!.fullPathURL == appPrefs.essentialURL {
                window!.title = notenikIO!.collection!.userFacingLabel() + " (E)"
            } else {
                window!.title = notenikIO!.collection!.userFacingLabel()
            }
            scroller = NoteScroller(collection: notenikIO!.collection!)
            
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
                viewCoordinator.addView(newView: listVC!)
            }
            
            if tagsVC == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message:"NoteTagsView Controller is nil!")
            } else {
                tagsVC!.io = newValue
                viewCoordinator.addView(newView: tagsVC!)
            }
            
            if editVC == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "NoteEditViewController is nil")
            } else {
                editVC!.io = newValue
                viewCoordinator.addView(newView: editVC!)
            }
            
            if notenikIO != nil {
                if let collection = notenikIO!.collection {
                    if collection.outlineTab {
                        let enabled = enableOutlineTab(nio: notenikIO!)
                        if !enabled {
                            collection.outlineTab = false
                        }
                    }
                }
            }
            
            if let windowStr = notenikIO?.collection?.windowPosStr {
                if !notenikIO!.collection!.readOnly {
                    setNumbers(windowStr)
                } else if notenikIO!.collection!.isRealmCollection {
                    setNumbers(windowStr)
                }
            }
            
            if displayVC != nil {
                displayVC!.loadResourcePagesForCollection(io: notenikIO!)
            }
            
            var (selected, position) = notenikIO!.getSelectedNote()
            if selected == nil {
                (selected, position) = notenikIO!.firstNote()
            }
            if selected != nil {
                _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                            note: selected,
                                            position: position,
                                            row: -1,
                                            searchPhrase: nil)
                // select(note: selected, position: position, source: .nav, andScroll: true)
            }
            
            buildReportsActionMenu()
            
            juggler.updateShowHideOutline()
            
            if notenikIO != nil {
                if let collection = notenikIO!.collection {
                    if collection.duplicates > 0 {
                        communicateError("Duplicates found within the Collection folder -- see Log for details", alert: true)
                    }
                }
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        viewCoordinator = CollectionViewCoordinator(collectionWindowController: self)
        shareButton.sendAction(on: .leftMouseDown)
        getWindowComponents()
        juggler.registerWindow(window: self)
        window!.delegate = self
        juggler.setLastSelection(title: "", link: "", filepath: "", wc: nil)
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let vc = displayVC else { return }
        guard let note = vc.note else { return }
        var filepath = ""
        if let fp = note.noteID.getFullPath(note: note) {
            filepath = fp
        }
        juggler.setLastSelection(title: note.title.value,
                                 link: note.getNotenikLink(preferringTimestamp: true),
                                 filepath: filepath,
                                 wc: self)
    }
    
    func windowWillClose() {
        juggler.windowClosing(wc: self)
    }
    
    /// Save important info before closing the Collection Window. 
    func saveBeforeClose() {

        if !pendingMod {
            let _ = modIfChanged()
        }
        applyCheckBoxUpdates()

        if  io != nil && io!.collection != nil {
            _ = saveNumbers()
        }
        finishFileCoordination()
    }
    
    /// Save position of window as a string by concatenating a series of formatted doubles.
    func saveNumbers() -> String {
        var windowPosition = ""
        if let frame = window?.frame {
            if let mainScreen = NSScreen.main {
                let visibleFrame = mainScreen.visibleFrame
                let maxY = visibleFrame.maxY
                let origin = frame.origin
                let size   = frame.size
                windowPosition.append("\(origin.x);")
                let originFlippedY = maxY - size.height - origin.y
                windowPosition.append("\(originFlippedY);")
                windowPosition.append("\(size.width);")
                windowPosition.append("\(size.height);")
            }
        }
        if let splitVC = splitViewController {
            windowPosition.append("\(splitVC.leftViewWidth);")
        }
        if let collection = io?.collection {
            collection.windowPosStr = windowPosition
            if collection.readOnly {
                if collection.fullPath.hasSuffix("tips") {
                    appPrefs.tipsWindow = windowPosition
                } else if collection.fullPath.hasSuffix("-KB") {
                    appPrefs.kbWindow = windowPosition
                } else if collection.isRealmCollection {
                    _ = RealmScanner.saveInfoFile(collection: collection)
                }
            }
        }
        return windowPosition
    }
    
    /// Set position of window, given a string of formatted doubles.
    func setNumbers(_ windowStr: String) {
    
        guard !windowStr.isEmpty else { return }
        let numbers = windowStr.components(separatedBy: ";")
        guard numbers.count >= 5 else { return }
        
        guard let x2 = Double(numbers[0]) else { return }
        guard let y2 = Double(numbers[1]) else { return }
        guard let w = Double(numbers[2]) else { return }
        guard let h = Double(numbers[3]) else { return }
        var x = x2
        let flippedY = y2
        var width = w
        var height = h
        
        guard let mainScreen = NSScreen.main else { return }
        let visibleFrame = mainScreen.visibleFrame
        let minX = visibleFrame.minX
        let maxX = visibleFrame.maxX
        let minY = visibleFrame.minY
        let maxY = visibleFrame.maxY
        
        if width > maxX - minX {
            let priorWidth = width
            width = maxX - minX
            logInfo(msg: "Window width adjusted from \(priorWidth) to \(width)")
        }
        
        if x < minX || x > maxX || x + width > maxX {
            let priorX = x
            x = minX
            logInfo(msg: "Window x coordinate adjusted from \(priorX) to \(x)")
        }
        
        if height > maxY - minY {
            let priorHeight = height
            height = maxY - minY
            logInfo(msg: "Window height adjusted from \(priorHeight) to \(height)")
        }
        
        var y = maxY - flippedY - height
        if y < minY || y > maxY || y + height > maxY {
            let priorY = y
            y = maxY - height
            logInfo(msg: "Window y coordinate adjusted from \(priorY) to \(y)")
        }
        
        let frame = NSRect(x: x, y: y, width: width, height: height)
        window!.setFrame(frame, display: true, animate: true)
        
        guard let divider = Double(numbers[4]) else { return }
        let float = CGFloat(divider)
        splitViewController!.splitView.setPosition(float, ofDividerAt: 0)
    }
    
    /// Let's grab the key components of the window and store them for easier access later
    func getWindowComponents() {
        if contentViewController != nil && contentViewController is NoteSplitViewController {
            splitViewController = contentViewController as? NoteSplitViewController
        }
        if splitViewController != nil {
            // let view = splitViewController!.view
            undoMgr = splitViewController!.undoManager
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
                viewCoordinator.addView(newView: displayVC!)
            }
        }
    }
    
    /// Respond to a user request to show/hide the list/tabs view.
    @IBAction func toggleListPane(_ sender: Any) {
        guard let splits = splitViewController else { return }
        if splits.leftViewCollapsed {
            changeLeftViewVisibility(makeVisible: true, narrow: false)
        } else {
            changeLeftViewVisibility(makeVisible: false, narrow: false)
        }
    }
    
    @IBAction func hideListNarrowWindow(_ sender: Any) {
        guard let splits = splitViewController else { return }
        if splits.leftViewCollapsed {
            changeLeftViewVisibility(makeVisible: true, narrow: false)
        } else {
            changeLeftViewVisibility(makeVisible: false, narrow: true)
        }
    }
    
    func changeLeftViewVisibility(makeVisible: Bool, narrow: Bool = false) {
        guard let splits = splitViewController else { return }
        let dividerPosition = splits.changeLeftViewVisibility(makeVisible: makeVisible)
        if makeVisible || !narrow {
            changeWindowWidth(shrink: false, minWidth: dividerPosition + minimumWindowWidth)
        } else {
            changeWindowWidth(shrink: true, minWidth: minimumWindowWidth)
        }
    }
    
    var wideWidth: CGFloat = 0.0
    
    func changeWindowWidth(shrink: Bool, minWidth: CGFloat) {
        guard let frame = window?.frame else { return }
        let origin = frame.origin
        let size   = frame.size
        let height = size.height
        let width = size.width
        var newWidth = width
        if shrink {
            wideWidth = width
            newWidth = width / 2.0
        } else if wideWidth > 0.0 {
            newWidth = wideWidth
        }
        if newWidth < minWidth {
            newWidth = minWidth
        }
        let newSize = NSSize(width: newWidth, height: height)
        let newRect = NSRect(origin: origin, size: newSize)
        window!.setFrame(newRect, display: true, animate: true)
    }
    
    @IBAction func toggleOutlineTab(_ sender: Any) {
        var success = false
        guard let io = notenikIO else { return }
        guard io.collectionOpen else { return }
        guard let collection = io.collection else { return }
        if collection.outlineTab {
            let disabled = disableOutlineTab()
            if disabled {
                collection.outlineTab = false
                success = true
            }
        } else {
            let enabled = enableOutlineTab(nio: io)
            if enabled {
                collection.outlineTab = true
                success = true
            }
        }
        if success {
            io.persistCollectionInfo()
            reloadCollection(self)
            juggler.updateShowHideOutline()
        }
    }
    
    func enableOutlineTab(nio: NotenikIO) -> Bool {
        guard nio.collection!.seqFieldDef != nil else {
            communicateError("The Outline Tab Cannot be Enabled Since the Collection has no Seq Field",
                             alert: true)
            return false
        }
        guard let tabs = collectionTabs else { return false }
        let selectedTab = tabs.selectedTabViewItemIndex
        if tabs.tabViewItems.count > 2 {
            tabs.tabViewItems.removeLast()
        }
        viewCoordinator.removeView(viewID: SeqOutlineViewController.staticViewID)
        seqOutlineVC = nil
        guard let collection = nio.collection else { return false }
        guard collection.seqFieldDef != nil else { return false }
        
        if let seqOutlineController = self.seqOutlineStoryboard.instantiateController(withIdentifier: "seqOutlineVC") as? SeqOutlineViewController {
            seqOutlineController.collectionWindowController = self
            seqOutlineController.io = nio
            seqOutlineVC = seqOutlineController
            let outlineTab = NSTabViewItem(viewController: seqOutlineController)
            outlineTab.label = "Outline"
            tabs.addTabViewItem(outlineTab)
            viewCoordinator.addView(newView: seqOutlineController)
            viewCoordinator.addView(newView: seqOutlineController)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Seq Outline View Controller!")
            return false
        }
        if selectedTab >= 0 && selectedTab < tabs.tabViewItems.count {
            tabs.selectedTabViewItemIndex = selectedTab
        }
        return true
    }
    
    func disableOutlineTab() -> Bool {
        guard let tabs = collectionTabs else { return false }
        if tabs.tabViewItems.count > 2 {
            tabs.tabViewItems.removeLast()
        }
        viewCoordinator.removeView(viewID: SeqOutlineViewController.staticViewID)
        return true
    }
    
    @IBAction func increaseBodyEditSpace(_ sender: Any) {
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        collection.minBodyEditViewHeight += 5.0
        adjustEditWindow()
        if let evc = editVC {
            evc.scrollToBottom()
        } else {
            print("No Edit View Controller Available!")
        }
    }
    
    @IBAction func decreaseBodyEditSpace(_ sender: Any) {
        guard let io = notenikIO else { return }
        guard let collection = io.collection else { return }
        if collection.minBodyEditViewHeight >= 10.0 {
            collection.minBodyEditViewHeight -= 5.0
            adjustEditWindow()
            if let evc = editVC {
                evc.scrollToBottom()
            } else {
                print("No Edit View Controller Available!")
            }
        }
    }
    
    func ensureQuotesMode() {
        
        if let splits = splitViewController {
            if splits.leftViewWidth > 0.0 {
                changeLeftViewVisibility(makeVisible: false, narrow: true)
            }
        }
    
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        if collection.displayMode != .quotations {
            collection.displayMode = .quotations
            noteIO.persistCollectionInfo()
            reloadCollection(self)
        }
    }
    
    @IBAction func copyNotenikURLforCollection(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }

        let str = CustomURLFormatter().open(collection: collection)
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Review and Possibly Update the Collection Prefs.
    //
    // -----------------------------------------------------------
    
    /// The user has requested a chance to review and possibly modify the Collection Preferences.
    @IBAction func menuCollectionPreferences(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard let lib = collection.lib else { return }
        guard !collection.readOnly else {
            communicateError("The Collection Settings cannot be adjusted for a read-only Collection", alert: true)
            return
        }
        guard !collection.isRealmCollection else {
            communicateError("The Collection Settings cannot be adjusted for a Project Folder Pseudo-Collection", alert: true)
            return
        }
        if let fileIO = noteIO as? FileIO {
            lib.checkStatus(type: .cssFolder)
            fileIO.loadCSSfiles()
        }
        preferredExt = collection.preferredExt
        noteFileFormat = collection.noteFileFormat
        backLinksDef = collection.backlinksDef
        hashtagsOption = collection.hashTagsOption
        defsRemoved.clear()
                
        if let collectionPrefsController = self.collectionPrefsStoryboard.instantiateController(withIdentifier: "collectionPrefsWC") as? CollectionPrefsWindowController {
            if let collectionPrefsWindow = collectionPrefsController.window {
                let collectionPrefsVC = collectionPrefsWindow.contentViewController as! CollectionPrefsViewController
                collectionPrefsVC.passCollectionPrefsRequesterInfo(collection: collection,
                                                                   window: collectionPrefsController,
                                                                   defsRemoved: defsRemoved)
                let returnCode = application.runModal(for: collectionPrefsWindow)
                if returnCode == NSApplication.ModalResponse.OK {
                    collectionPrefsModified()
                }
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Collection Prefs Window Controller!")
        }
    }
    
    /// If the user requested that Collection Prefs be updated, figure out what to do next.
    func collectionPrefsModified() {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        if noteIO is FileIO {
            let fileIO = noteIO as! FileIO
            if collection.preferredExt != preferredExt {
                let renameOK = fileIO.changePreferredExt(from: preferredExt,
                                                         to: fileIO.collection!.preferredExt)
                if !renameOK {
                    noteIO.collection!.preferredExt = preferredExt
                }
            }
            var hashtagsUpdate = false
            if collection.hashTagsOption != hashtagsOption
                && collection.hashTagsOption != .inlineHashtags
                && hashtagsOption != .inlineHashtags {
                hashtagsUpdate = true
            }
            if collection.noteFileFormat != noteFileFormat || hashtagsUpdate {
                confirmFileFormatChange(fileIO: fileIO, collection: collection)
            }
            /* if collection.selCSSfile.isEmpty {
                fileIO.loadDisplayCSS()
            } */
        }
        removeFields()
        
        if collection.backlinksDef != nil && backLinksDef == nil {
            addBackLinks()
        }
        noteIO.persistCollectionInfo()
        reloadCollection(self)
    }
    
    // If the user requested a file format change, let's see if they're serious.
    func confirmFileFormatChange(fileIO: FileIO, collection: NoteCollection) {
        let alert = NSAlert()
        var msg = "Are you sure you want to change your file storage format? \n"
        if noteFileFormat != collection.noteFileFormat {
            msg.append( "  - from \(noteFileFormat.forDisplay) to \(collection.noteFileFormat.forDisplay) \n")
        }
        if hashtagsOption != collection.hashTagsOption {
            if collection.hashTagsOption == .fieldWithHashSymbols {
                msg.append("  - adding hash tags")
            } else {
                msg.append("  - removing hash tags")
            }
        }
        if collection.noteFileFormat == .plainText || collection.noteFileFormat == .markdown {
            msg.append("Data loss may result.")
        }
        alert.messageText = msg
        alert.addButton(withTitle: "Yes - Proceed")
        alert.addButton(withTitle: "No - Cancel")
        let response = alert.runModal()
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            performFileFormatChange(fileIO: fileIO)
        case NSApplication.ModalResponse.alertSecondButtonReturn:
            collection.noteFileFormat = noteFileFormat
            break
        default:
            break
        }

    }
    
    /// Let's rewrite the entire Collection.
    func performFileFormatChange(fileIO: FileIO) {
        
        // Offer the user a chance to perform a backup.
        let alert = NSAlert()
        alert.messageText = "A backup is recommended before making a change to your file storage format. "
        alert.addButton(withTitle: "OK - Proceed with Backup")
        alert.addButton(withTitle: "No - Skip the Backup")
        let response = alert.runModal()
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
            backupToZip(self)
        default:
            break
        }
        
        // Now rewrite the Collection to disk.
        let newFormat = fileIO.collection!.noteFileFormat
        let newHashtagsOption = fileIO.collection!.hashTagsOption
        var updated = 0
        var (note, position) = fileIO.firstNote()
        while note != nil {
            note!.noteID.setNoteFileFormat(newFormat: newFormat)
            if let tagsField = note!.getTagsAsField() {
                if let tags = tagsField.value as? TagsValue {
                    tags.hashtagsOption = newHashtagsOption
                }
            }
            let written = fileIO.writeNote(note!)
            if written {
                updated += 1
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .error,
                                  message: "Problems saving note titled \(note!.title)")
            }
            (note, position) = fileIO.nextNote(position)
        }
        
        let alert2 = NSAlert()
        alert2.messageText = "Note File Format changes have been completed."
        alert2.runModal()
    }
    
    /// Remove fields no longer needed by the user.
    func removeFields() {

        guard defsRemoved.count > 0 else { return }
        guard let noteIO = guardForCollectionAction() else { return }
        
        var notesToUpdate: [Note] = []
        var (note, position) = noteIO.firstNote()
        while note != nil {
            var noteUpdated = false
            for def in defsRemoved.list {
                let field = note!.getField(def: def)
                if field != nil {
                    noteUpdated = true
                }
            }
            if noteUpdated {
                notesToUpdate.append(note!)
            }
            (note, position) = noteIO.nextNote(position)
        }
        for noteToUpdate in notesToUpdate {
            let modNote = noteToUpdate.copy() as! Note
            for def in defsRemoved.list {
                let field = modNote.getField(def: def)
                if field != nil {
                    modNote.removeField(def: def)
                }
            }
            _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        finishBatchOperation()
        if notesToUpdate.count > 0 {
            reportNumberOfNotesUpdated(notesToUpdate.count)
        }
    }
    
    func addBackLinks() {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        let mogi = Transmogrifier(io: noteIO)
        let backlinks = mogi.generateBacklinks()
        
        finishBatchOperation()
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        if backlinks == 0 {
            alert.messageText = "No Backlinks were generated"
        } else if backlinks == 1 {
            alert.messageText = "1 Backlink was generated"
        } else {
            alert.messageText = "\(backlinks) Backlinks were generated"
        }
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Update the Note Identification Settings
    //
    // -----------------------------------------------------------
    
    var uniqueIdRule: NoteIdentifierRule = .titleOnly
    var noteIdAuxField = ""
    var textIdRule: NoteIdentifierRule = .titleOnly
    var textIdSep = ""
    
    /// The user has requested a chance to review and possibly modify the Note ID Settings.
    @IBAction func menuNoteIdPreferences(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard !collection.readOnly else {
            communicateError("The Note ID Config cannot be adjusted for a read-only Collection", alert: true)
            return
        }
        guard !collection.isRealmCollection else {
            communicateError("The Note ID Config cannot be adjusted for a Project Folder Pseudo-Collection", alert: true)
            return
        }
                
        if let idPrefsController = self.idPrefsStoryboard.instantiateController(withIdentifier: "idPrefsWC") as? IdPrefsWindowController {
            if let idPrefsWindow = idPrefsController.window {
                let idPrefsVC = idPrefsWindow.contentViewController as! IdPrefsViewController
                idPrefsVC.passIdPrefsRequesterInfo(collection: collection, window: idPrefsController)
                let returnCode = application.runModal(for: idPrefsWindow)
                if returnCode == NSApplication.ModalResponse.OK {
                    noteIdConfigModified()
                }
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Note ID Settings Window Controller!")
        }
    }
    
    func noteIdConfigModified() {
 
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        let notesFolder = collection.lib.getPath(type: .notes)
        var notesList: [Note] = []
        var oldFilenames: [String] = []
        var notesRenamed = 0
        for note in noteIO.notesList {
            if let existingFilename = note.noteID.getExistingBaseDotExt() {
                notesList.append(note)
                oldFilenames.append(existingFilename)
            } else {
                if let filename = note.noteID.getBaseDotExt() {
                    notesList.append(note)
                    oldFilenames.append(filename)
                }
            }
        }
        let path = noteIO.collection!.fullPath
        let readOnly = noteIO.collection!.readOnly
        saveBeforeClose()
        noteIO.closeCollection()
        
        var i = 0
        while i < notesList.count {
            let note = notesList[i]
            let oldFilename = oldFilenames[i]
            note.identify()
            note.noteID.setIDSourceMatch(true)
            var newFilename = note.noteID.getBaseDotExt()
            if newFilename != nil {
                if newFilename != oldFilename {
                    let oldPath = FileUtils.joinPaths(path1: notesFolder, path2: oldFilename)
                    var renameDone = false
                    var dupeCounter = 1
                    let originalTitle = note.title.value
                    while !renameDone {
                        let newPath = FileUtils.joinPaths(path1: notesFolder, path2: newFilename!)
                        do {
                            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
                            renameDone = true
                            notesRenamed += 1
                        } catch let error as NSError {
                            communicateError("Could not rename file from \(oldPath) to \(newPath) due to \(error)", alert: true)
                            dupeCounter += 1
                            _ = note.setTitle("\(originalTitle) \(dupeCounter)")
                            note.identify()
                            newFilename = note.noteID.getBaseDotExt()
                        }
                    }
                }
            }
            i += 1
        }
        
        reportNumberOfNotesUpdated(notesRenamed )
            
        notesList = []
        oldFilenames = []
        
        newNoteRequested = false
        pendingMod = false
        pendingEdits = false
        
        let (_, newIO) = multi.provision(collectionPath: path, inspector: nil, readOnly: readOnly)
        
        self.io = newIO
        
    }
    
    @IBAction func importFromWikiQuote(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        if let wqController = self.wikiQuoteStoryboard.instantiateController(withIdentifier: "wikiQuoteWC") as? WikiQuoteWindowController {
            wqController.io = noteIO
            wqController.cwc = self
            wqController.showWindow(self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Wiki Quote Window Controller!")
        }
    }
    
    func newNote(quote: Quote) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard !quote.text.isEmpty else { return }
        
        newNote = Note(collection: noteIO.collection!)
        
        _ = newNote!.setBody(quote.text)
        _ = newNote!.setTitle(StringUtils.summarize(quote.text, max: 60, ellipsis: false))
        _ = newNote!.setAuthor(quote.author)
        _ = newNote!.setDate(quote.date)
        if !quote.link.isEmpty {
            _ = newNote!.setLink(quote.link)
        }
        if !quote.majorTitle.isEmpty {
            _ = newNote!.setField(label: NotenikConstants.workTitleCommon, value: quote.majorTitle)
            _ = newNote!.setField(label: NotenikConstants.workTypeCommon, value: "Major Work")
        } else {
            _ = newNote!.setField(label: NotenikConstants.workTitleCommon, value: quote.minorTitle)
            _ = newNote!.setField(label: NotenikConstants.workTypeCommon, value: "Minor Work")
        }
        
        newNoteRequested = true
        editVC!.configureEditView(noteIO: noteIO)
        editVC!.refreshLookupData()
        editVC!.populateFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
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
    
    /// Respond to user request to rename/add/remove a field.
    @IBAction func renameAddRemoveField(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        if let renameController = self.fieldRenameStoryboard.instantiateController(withIdentifier: "fieldRenameWC") as? FieldRenameWindowController {
            renameController.io = noteIO
            renameController.cwc = self
            renameController.showWindow(self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Field Rename Window Controller!")
        }
    }
    
    /// Execute the user's request to rename/add/remove a field.
    func renameAddRemoveNow(parms: FieldRenameParms, vc: FieldRenameViewController) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        if parms.remove {
            let proceed = confirmAction(msg: "Really remove field titled \(parms.existingFieldLabel)? Any existing contents of this field will be lost.")
            guard proceed else { return }
        }
        let dict = collection.dict
        
        var oldDef: FieldDefinition? = nil
        
        if parms.removeOrRename {
            oldDef = dict.getDef(parms.existingFieldLabel)
        }
        
        if parms.rename && oldDef!.fieldType.typeString == NotenikConstants.titleCommon {
            collection.newLabelForTitle = parms.newFieldLabel
            renameSpecialField(parms: parms, noteIO: noteIO, collection: collection, vc: vc)
        } else if parms.rename && oldDef!.fieldType.typeString == NotenikConstants.bodyCommon {
            collection.newLabelForBody = parms.newFieldLabel
            renameSpecialField(parms: parms, noteIO: noteIO, collection: collection, vc: vc)
        } else {
            renameOrdinaryField(parms: parms,
                                noteIO: noteIO,
                                collection: collection,
                                oldDef: oldDef,
                                vc: vc)
        }
        
        // Report results to the user
        let alert = NSAlert()
        alert.alertStyle = .informational
        var rr = ""
        var ar = ""
        var msg = ""
        switch parms.action {
        case .add:
            msg = "Added a New Field:"
            ar = "Added"
        case .remove:
            msg = "Removed an Existing Field:"
            rr = "Removed"
        case .rename:
            msg = "Renamed an Existing Field:"
            rr = "Renamed"
            ar = "With"
        }
        msg.append("\n")
        if parms.removeOrRename {
            msg.append("\(rr) field labeled \(parms.existingFieldLabel)")
        }
        if parms.rename {
            msg.append("\n")
        }
        if parms.addOrRename {
            msg.append("\(ar) field labeled \(parms.newFieldLabel), with type of \(parms.newFieldType)")
        }
        alert.messageText = msg
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    func renameSpecialField(parms: FieldRenameParms,
                            noteIO: NotenikIO,
                            collection: NoteCollection,
                            vc: FieldRenameViewController) {
        var updated = 0
        var (note, position) = noteIO.firstNote()
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
        noteIO.persistCollectionInfo()
        vc.window!.close()
        reloadCollection(self)
        logInfo(msg: "Notes with field changes = \(updated)")
    }
    
    func renameOrdinaryField(parms: FieldRenameParms,
                             noteIO: NotenikIO,
                             collection: NoteCollection,
                             oldDef: FieldDefinition?,
                             vc: FieldRenameViewController) {
        
        let dict = collection.dict
        
        var newDef: FieldDefinition? = nil
        
        if parms.addOrRename {
            newDef = FieldDefinition(typeCatalog: noteIO.collection!.typeCatalog,
                                     label: parms.newFieldLabel,
                                     type: parms.newFieldType)
            if newDef != nil {
                var family: String?
                if !parms.typeConfigText.isEmpty {
                    newDef!.applyTypeConfig(parms.typeConfigText, collection: collection)
                } else if parms.rename && oldDef!.fieldType.typeString == newDef!.fieldType.typeString {
                    let configStr = oldDef!.extractTypeConfig(collection: collection)
                    newDef!.applyTypeConfig(configStr, collection: collection)
                }
                if parms.rename {
                    family = oldDef!.fieldLabel.commonForm
                }
                
                dict.unlock()
                _ = dict.addDef(newDef!, family: family)
                dict.lock()
            }
        }
                
        var notesToUpdate: [Note] = []
        
        if parms.removeOrRename {
            
            var (note, position) = noteIO.firstNote()
            while note != nil {
                let oldField = note!.getField(label: parms.existingFieldLabel)
                if oldField != nil {
                    notesToUpdate.append(note!)
                }
                (note, position) = noteIO.nextNote(position)
            }
                        
            for noteToUpdate in notesToUpdate {
                let modNote = noteToUpdate.copy() as! Note
                let oldField = modNote.getField(label: parms.existingFieldLabel)
                if oldField != nil {
                    if parms.rename {
                        let newValue = newDef!.fieldType.createValue(oldField!.value.value)
                        let newField = NoteField(def: newDef!, value: newValue)
                        modNote.removeField(def: oldDef!)
                        _ = modNote.setField(newField)
                    } else {
                        modNote.removeField(def: oldDef!)
                    }
                    if let noteID = editVC?.selectedNote?.id {
                        if noteID == modNote.id {
                            populateEditFields(with: modNote)
                        }
                    }
                }
                _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
            }
            _ = dict.removeDef(oldDef!)
            
        } else if parms.add && !parms.newFieldDefault.isEmpty {
            var (note, position) = noteIO.firstNote()
            while note != nil {
                let modNote = note!.copy() as! Note
                let newValue = newDef!.fieldType.createValue(parms.newFieldDefault)
                let newField = NoteField(def: newDef!, value: newValue)
                _ = modNote.setField(newField)
                if let noteID = editVC?.selectedNote?.id {
                    if noteID == modNote.id {
                        populateEditFields(with: modNote)
                    }
                }
                _ = io!.modNote(oldNote: note!, newNote: modNote)
                (note, position) = noteIO.nextNote(position)
            }
        }
                
        noteIO.persistCollectionInfo()
        vc.window!.close()
        reloadCollection(self)
        logInfo(msg: "Notes with field changes = \(notesToUpdate.count)")
    }
    
    /// Prepare a new note, with default fields and values taken from a class template
    /// - Parameter sender: Requested via a menu item.
    @IBAction func menuNewNoteWithOptions(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        let errorMsg = NewWithOptionsWindowController.checkEligibility(collection: collection)
        guard errorMsg.isEmpty else {
            communicateError(errorMsg, alert: true)
            return
        }
        
        let (note, _) = noteIO.getSelectedNote()
        if let newWithOptionsController =
            self.newWithOptionsStoryboard.instantiateController(withIdentifier: "newWithOptionsWC") as? NewWithOptionsWindowController {
            newWithOptionsController.showWindow(self)
            newWithOptionsController.noteIO = noteIO
            newWithOptionsController.collectionWC = self
            if note != nil {
                newWithOptionsController.setCurrentNote(note!)
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a New With Options Window Controller!")
        }
    }
    
    public func newWithOptions(currentNote: Note?) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        let errorMsg = NewWithOptionsWindowController.checkEligibility(collection: collection)
        guard errorMsg.isEmpty else {
            communicateError(errorMsg, alert: true)
            return
        }
        
        let (note, _) = noteIO.getSelectedNote()
        if let newWithOptionsController =
            self.newWithOptionsStoryboard.instantiateController(withIdentifier: "newWithOptionsWC") as? NewWithOptionsWindowController {
            newWithOptionsController.showWindow(self)
            newWithOptionsController.noteIO = noteIO
            newWithOptionsController.collectionWC = self
            if note != nil {
                newWithOptionsController.setCurrentNote(note!)
            }
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a New from Klass Window Controller!")
        }
    }
    
    func seqModify(startingRow: Int, endingRow: Int) {
        guard let noteIO = guardForCollectionAction() else { return }
        if let seqModController = self.seqModStoryboard.instantiateController(withIdentifier: "seqModWC") as? SeqModWindowController {
            seqModController.showWindow(self)
            seqModController.noteIO = noteIO
            seqModController.collectionWC = self
            seqModController.setRange(startingRow: startingRow, endingRow: endingRow)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos", category: "CollectionWindowController", level: .fault, message: "Couldn't get a Seq Mod Window Controller")
        }
    }
    
    public func seqModified(modStartingNote: Note?, rowCount: Int, reselect: Bool = true) {
        newNoteRequested = false
        pendingEdits = false
        reloadCollection(self)
        if reselect {
            if modStartingNote != nil {
                _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                            note: modStartingNote,
                                            position: nil, row: -1, searchPhrase: nil)
                // select(note: modStartingNote!, position: nil, source: .nav, andScroll: true)
                if listVC != nil && rowCount > 1 {
                    listVC!.extendSelection(rowCount: rowCount)
                }
            } else {
                let (note, position) = io!.firstNote()
                _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                            note: note, position: position,
                                            row: -1, searchPhrase: nil)
                // select(note: note, position: position, source: .nav, andScroll: true)
            }
        }
    }
    
    /// Allow the user to add a new Class template.
    /// - Parameter sender: Requested via a menu item.
    @IBAction func newKlassTemplate(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        var klasses = false
        var klassFieldDef: FieldDefinition?
        if let kfd = collection.klassFieldDef {
            klasses = true
            klassFieldDef = kfd
            // communicateError("Collection does not define a Class field", alert: true)
            // return
        }
        guard let lib = collection.lib else { return }
        let klassFolderResource = lib.ensureResource(type: .klassFolder)
        guard klassFolderResource.isAvailable else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save and Edit New Class Template"
        savePanel.nameFieldLabel = "Class name: "
        savePanel.directoryURL = klassFolderResource.url
        if klasses {
            savePanel.nameFieldStringValue = "classname." + collection.preferredExt
        } else {
            savePanel.nameFieldStringValue = NotenikConstants.defaultsKlass + "." + collection.preferredExt
        }
        var allowedFileTypes: [String] = []
        allowedFileTypes.append(collection.preferredExt)
        savePanel.allowedFileTypes = allowedFileTypes
        let userChoice = savePanel.runModal()
        guard userChoice == .OK else { return }
        guard let url = savePanel.url else { return }
        let klassName = url.deletingPathExtension().lastPathComponent
        var klassTemplate = ""
        for def in collection.dict.list {
            if klasses && def.fieldLabel.commonForm == klassFieldDef!.fieldLabel.commonForm {
                klassTemplate.append("\(def.fieldLabel.properForm): \(klassName)\n\n")
            } else {
                klassTemplate.append("\(def.fieldLabel.properForm): \n\n")
            }
        }
        do {
            try klassTemplate.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
        } catch {
            communicateError("Problems writing the file", alert: true)
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
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: noteToUpdate,
                                    position: nil, row: -1, searchPhrase: nil)
        // select(note: noteToUpdate, position: nil, source: .action, andScroll: true)
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return }
        var body = selectedNote.body.value
        let updatedNote = selectedNote.copy() as! Note
        body.append("\n\n")
        body.append(bodyText)
        guard updatedNote.setBody(body) else { return }
        newNoteRequested = false
        populateEditFields(with: updatedNote)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    func populateEditFields(with note: Note) {
        if note.collection.klassFieldDef != nil {
            let klassName = note.klass.value
            if !klassName.isEmpty {
                editVC!.configureEditView(noteIO: io!, klassName: klassName)
            }
        }
        editVC!.refreshLookupData()
        editVC!.populateFields(with: note)
    }
    
    /// Adjust  the edit window to reflect any changes in the UI appearance.
    func adjustEditWindow() {
        let editing = noteTabs!.tabView.selectedTabViewItem!.label == "Edit"
        guard let noteIO = io else { return }
        var klassName: String?
        var note = editVC!.selectedNote
        if editing {
            let (outcome, modNote) = modIfChanged()
            if modNote != nil {
                note = modNote
            }
            guard outcome != .tryAgain else { return }
        }
        if note != nil && note!.hasKlass() {
            klassName = note!.klass.value
        }
        editVC!.containerViewBuilt = false
        editVC!.configureEditView(noteIO: noteIO, klassName: klassName)
        if note != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID, 
                                                  note: note,
                                                  position: nil, row: -1, searchPhrase: nil)
            /* select(note: note,
                   position: nil,
                   source: .action,
                   andScroll: true,
                   searchPhrase: nil) */
            if editing {
                openEdits(self)
            }
        }
    }
    
    func newNote(title: String, bodyText: String) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        _ = newNote!.setTitle(title)
        _ = newNote!.setBody(bodyText)
        populateEditFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    func newNote(klassDef: KlassDef) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        let templateNote = klassDef.defaultValues!
        _ = newNote!.setKlass(klassDef.name)
        for (_, field) in templateNote.fields {
            if !field.value.value.isEmpty {
                if field.def.shouldInitFromKlassTemplate {
                    _ = newNote!.setField(label: field.def.fieldLabel.properForm, value: field.value.value)
                }
            }
        }
        setFollowing()
        editVC!.configureEditView(noteIO: noteIO, klassName: klassDef.name)
        editVC!.populateFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    func newNote(title: String? = nil,
                 bodyText: String? = nil,
                 klassName: String? = nil,
                 level: String? = nil,
                 seq:   String? = nil,
                 addAndReturn: Bool = false) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        newNote = Note(collection: noteIO.collection!)
        
        if title != nil && !title!.isEmpty {
            _ = newNote!.setTitle(title!)
        }
        
        applyKlassTemplate(noteIO: noteIO, klassName: klassName)
        
        if klassName != nil && !klassName!.isEmpty && !newNote!.hasKlass() {
            _ = newNote!.setKlass(klassName!)
        }
        
        if level != nil && !level!.isEmpty && collection.levelFieldDef != nil {
            _ = newNote!.setLevel(level!)
        }
        
        if seq != nil && !seq!.isEmpty && collection.seqFieldDef != nil {
            _ = newNote!.setSeq(seq!)
        }
        
        if bodyText != nil && !bodyText!.isEmpty {
            _ = newNote!.setBody(bodyText!)
        }
        
        if level == nil && seq == nil {
            setFollowing()
        }
        
        if addAndReturn {
            newNote!.identify()
            let newNote = addPastedNote(newNote!)
            // reloadViews()
            if newNote != nil {
                _ = viewCoordinator.focusOn(initViewID: collectionViewID, 
                                            note: newNote!,
                                            position: nil, row: -1, searchPhrase: nil,
                                            withUpdates: true)
                // select(note: newNote!, position: nil, source: .action, andScroll: true)
                newWithOptions(currentNote: newNote!)
            }
        } else {
            newNoteRequested = true
            editVC!.configureEditView(noteIO: noteIO, klassName: klassName)
            editVC!.refreshLookupData()
            editVC!.populateFields(with: newNote!)
            noteTabs!.tabView.selectTabViewItem(at: 1)
            guard let window = self.window else { return }
            guard let titleView = editVC?.titleView else { return }
            window.makeFirstResponder(titleView.view)
        }
    }
    
    func applyKlassTemplate(noteIO: NotenikIO, klassName: String?) {
        
        guard let collection = noteIO.collection else { return }
        let klassDefs = collection.klassDefs
        guard !klassDefs.isEmpty else { return }
        
        var klsName = NotenikConstants.defaultsKlass
        var realKlass = false
        if let name = klassName {
            if !name.isEmpty {
                klsName = name
                realKlass = true
                _ = newNote!.setKlass(name)
            }
        }
        
        var defFound = false
        var klassDef: KlassDef?
        for nextDef in klassDefs {
            if klsName == nextDef.name {
                if realKlass {
                    collection.lastNewKlass = klsName
                }
                defFound = true
                klassDef = nextDef
                break
            }
        }
                                      
        guard defFound else { return }
        
        let templateNote = klassDef!.defaultValues!

        for (_, field) in templateNote.fields {
            if !field.value.value.isEmpty {
                if field.def.shouldInitFromKlassTemplate {
                    _ = newNote!.setField(label: field.def.fieldLabel.properForm, value: field.value.value)
                } else if field.def.fieldType.typeString == NotenikConstants.titleCommon {
                    if newNote!.title.value.isEmpty {
                        let defaultTitle = field.value.value
                        if defaultTitle.hasSuffix("#") {
                            var titleTextCount = defaultTitle.count
                            var hashCount = 0
                            var trailingIndex = defaultTitle.endIndex
                            var spaceCount = 0
                            var scanDone = false
                            while trailingIndex > defaultTitle.startIndex && !scanDone {
                                trailingIndex = defaultTitle.index(before: trailingIndex)
                                if defaultTitle[trailingIndex] == "#" && spaceCount == 0 {
                                    hashCount += 1
                                    titleTextCount -= 1
                                } else if defaultTitle[trailingIndex].isWhitespace {
                                    titleTextCount -= 1
                                    spaceCount += 1
                                } else {
                                    scanDone = true
                                }
                            }
                            let titleLeft = String(defaultTitle.prefix(titleTextCount))
                            let numberFormat = "%0\(hashCount)d"
                            let number = collection.nextTitleNumber()
                            let titleRight = String(format: numberFormat, number)
                            _ = newNote!.setTitle(titleLeft + " " + titleRight)
                        } else {
                            _ = newNote!.setTitle(field.value.value)
                        }
                    }
                }
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Batch operations performed on the entire Collection.
    //
    // -----------------------------------------------------------
    
    @IBAction func generateBacklinks(_ sender: Any) {

        // Make sure we're in a position to perform this operation.
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard collection.backlinksDef != nil else {
            communicateError("Backlinks must first be defined as a field for this Collection",
                             alert: true)
            return
        }
        
        let mogi = Transmogrifier(io: noteIO)
        let backlinks = mogi.generateBacklinks()
        
        // Now let the user see the results.
        finishBatchOperation()
        reloadCollection(self)
        let alert = NSAlert()
        alert.alertStyle = .informational
        if backlinks == 0 {
            alert.messageText = "No Backlinks were generated"
        } else if backlinks == 1 {
            alert.messageText = "1 Backlinks was generated"
        } else {
            alert.messageText = "\(backlinks) Backlinks were generated"
        }
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
        
    }
    
    /// Renumber the Collection's sequence numbers based on the level and position of each note.
    @IBAction func renumberSeqBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: true, tagsAction: .ignore)
    }
    
    @IBAction func replaceTagsBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: false, tagsAction: .update)
    }
    
    @IBAction func updateSeqAndTagsBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: true, tagsAction: .update)
    }
    
    @IBAction func removeTagsBasedOnLevel(_ sender: Any) {
        outlineUpdatesBasedOnLevel(updateSeq: false, tagsAction: .remove)
    }
    
    /// Update Seq and/or Tags field based on outline structure (based on seq + level).
    func outlineUpdatesBasedOnLevel(updateSeq: Bool, tagsAction: SeqTagsAction) {
        
        // Make sure we're in a position to perform this operation.
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        guard collection.levelFieldDef != nil else {
            communicateError("The Collection must contain a Level field before it can be Renumbered or Retagged",
                             alert: true)
            return
        }
        
        guard let sequencer = Sequencer(io: noteIO) else {
            communicateError("Collection must be sorted by Seq before it can be renumbered or retagged",
                             alert: true)
            return
        }
        
        let (numberOfUpdates, errorMsg) = sequencer.outlineUpdatesBasedOnLevel(updateSeq: updateSeq,
                                                                               tagsAction: tagsAction)
        if !errorMsg.isEmpty {
            communicateError(errorMsg, alert: true)
        }
        
        // Now let the user see the results.
        finishBatchOperation()
        reloadCollection(self)
        reportNumberOfNotesUpdated(numberOfUpdates)
    }
        
    /// If we have past due daily tasks, then update the dates to make them current
    @IBAction func menuCatchUpDailyTasks(_ sender: Any) {
        
        guard io != nil && io!.collectionOpen else { return }
        
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        applyCheckBoxUpdates()
        
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
            _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        // reloadViews()
        (note, position) = io!.firstNote()
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note, 
                                    position: position, row: -1, searchPhrase: nil,
                                    withUpdates: true)
        // select(note: note, position: position, source: .nav, andScroll: true)
    }
    
    /// If we have tasks that have been completed, but not closed, then close them now.
    @IBAction func closeAllCompletedTasks(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        var (note, position) = noteIO.firstNote()
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
        var updated = 0
        while note != nil {
            if note!.hasDate() {
                let written = noteIO.writeNote(note!)
                if !written {
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
    
    func bulkEdit(notes: [Note]) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard !collection.readOnly else {
            communicateError("A Bulk Edit cannot be performed on a read-only Collection", alert: true)
            return
        }
        
        if let bulkEditController = self.bulkEditStoryboard.instantiateController(withIdentifier: "bulkEditWC") as? BulkEditWindowController {
            bulkEditController.showWindow(self)
            bulkEditController.passRequestInfo(io: noteIO, collectionWC: self, selNotes: notes)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Bulk Edit Window Controller!")
        }
    }
    
    func bulkEditOK(fieldSelected: String, valueToAssign: String, notes: [Note], vc: BulkEditViewController) {
        
        guard !notes.isEmpty else { return }
        guard let noteIO = guardForCollectionAction() else { return }
        guard let def = noteIO.collection?.dict.getDef(fieldSelected) else { return }
        
        guard confirmAction(msg: "Proceed with Bulk Edit?",
                            info: "This will change the field labeled \(def.fieldLabel.properForm) to a value of '\(valueToAssign)' for \(notes.count) notes") else {
            return
        }
        
        var firstNote: Note?
        
        for noteToUpdate in notes {
            let modNote = noteToUpdate.copy() as! Note
            if let field = modNote.getField(def: def) {
                if let multi = field.value as? MultiValues {
                    multi.append(valueToAssign)
                } else {
                    field.setValue(valueToAssign)
                }
            } else {
                _ = modNote.setField(label: def.fieldLabel.commonForm, value: valueToAssign)
            }
            if firstNote == nil {
                firstNote = modNote
            }
            _ = io!.modNote(oldNote: noteToUpdate, newNote: modNote)
        }
        vc.window!.close()
        // reloadViews()
        if firstNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: firstNote,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: firstNote, position: nil, source: .nav, andScroll: true)
        } else {
            let (note, position) = io!.firstNote()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: position, row: -1, searchPhrase: nil)
            // select(note: note, position: position, source: .nav, andScroll: true)
        }
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
    
    /// Get the desired tag to be assigned to the search results.
    @IBAction func tagSearchResults (_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        searcher.checkUserInput(str: searchField.stringValue)
        guard searcher.hasText else {
            communicateError("No search text available", alert: true)
            return
        }
        
        (tagStartNote, tagStartPosition) = searcher.nextMatching(startNew: true)
        
        if tagStartNote != nil {
            if let tagsAssignController = self.tagsAssignStoryboard.instantiateController(withIdentifier: "tagsAssignWC") as? TagsAssignWindowController {
                tagsAssignController.showWindow(self)
                tagsAssignController.passCollectionInfo(io: noteIO, collectionWC: self)
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Couldn't get a Tags Assign Window Controller!")
            }
        } else {
            communicateError("No Notes found matching search criteria", alert: true)
        }
    }
    
    var tagStartNote: Note?
    var tagStartPosition: NotePosition = NotePosition()
    
    /// Assign the specified tag to the current search results.
    func tagAssignNow(to: String, vc: TagsAssignViewController) {
        
        guard to.count > 0 else {
            vc.window!.close()
            communicateError("No tag to assign", alert: true)
            return
        }
        
        guard let noteIO = guardForCollectionAction() else {
            vc.window!.close()
            return
        }
        
        var updated = 0
        var (note, _) = searcher.nextMatching(startNew: true)
        while note != nil {
            updated += 1
            var tagStr = note!.tags.value
            if !tagStr.isEmpty {
                tagStr.append(", ")
            }
            tagStr.append(to)
            let modNote = note!.copy() as! Note
            _ = modNote.setTags(tagStr)
            _ = noteIO.modNote(oldNote: note!, newNote: modNote)
            (note, _) = searcher.nextMatching(startNew: false)
        }
        
        vc.window!.close()
        // reloadViews()
        if tagStartNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: tagStartNote,
                                        position: tagStartPosition,
                                        row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: tagStartNote, position: tagStartPosition, source: .action)
        } else {
            let (note, position) = io!.firstNote()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: position, row: -1, searchPhrase: nil)
            // select(note: note, position: position, source: .action, andScroll: true)
        }
        logInfo(msg: "Notes with tags added = \(updated)")
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
        let _ = maker.putNote(selectedNote, includeAttachments: true)
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
    func pasteItems(_ pbItems: [NSPasteboardItem],
                    row: Int,
                    dropOperation: NSTableView.DropOperation) -> Int {
        
        // Make sure we're ready to do stuff.
        guard let noteIO = guardForCollectionAction() else { return 0 }
        guard let collection = noteIO.collection else { return 0 }
        let seqDef = collection.seqFieldDef
        
        var newLevel: LevelValue?
        var newSeq: SeqValue?
        var newKlass: KlassValue?
                            
        // Gen Seq and Level, if appropriate
        if row > 0 && dropOperation == .above && seqDef != nil
            && (collection.sortParm == .seqPlusTitle || collectionTabs!.selectedTabViewItemIndex == 2) {
            let seqType = seqDef!.fieldType as! SeqType
            var seqAbove = seqType.createValue() as! SeqValue
            let noteAbove = noteIO.getNote(at: row - 1)
            var levelAbove: LevelValue = LevelValue()
            if noteAbove != nil {
                seqAbove = noteAbove!.seq
                levelAbove = noteAbove!.level
                newLevel = noteAbove!.level
                if noteAbove!.hasKlass() {
                    newKlass = KlassValue(noteAbove!.klass.value)
                }
            }
            let noteBelow = noteIO.getNote(at: row)
            if noteBelow != nil {
                let belowLevel = noteBelow!.level
                if newLevel == nil {
                    newLevel = belowLevel
                } else if belowLevel > newLevel! {
                    newLevel = belowLevel
                }
                if newKlass == nil && noteBelow!.hasKlass() {
                    newKlass = KlassValue(noteBelow!.klass.value)
                }
            }
            if noteAbove != nil {
                newSeq = seqAbove.dupe()
            }
            if newSeq != nil && newLevel != nil {
                newSeq!.incByLevels(originalLevel: levelAbove, newLevel: newLevel!)
            }
        }
        
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
            
            var attachmentPaths = ""
            
            if url != nil && title != nil {
                logInfo(msg: "Processing pasted item as URL: \(title!)")
                logInfo(msg: "URL as passed: \(url!)")
                _ = note.setTitle(title!)
                _ = note.setLink(url!)
            } else if vcard != nil {
                logInfo(msg: "Processing pasted item as VCard")
                let contacts = ContactCards()
                let contactNotes = contacts.parse(vcard!, collection: collection)
                for contactNote in contactNotes {
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
                let likelyText = ResourceFileSys.isLikelyNoteFile(fileURL: fileURL, preferredNoteExt: collection.preferredExt)
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                let ext = fileURL.pathExtension
                if ext == "opml" {
                    let defaultTitle = StringUtils.wordDemarcation(fileName,
                                                                   caseMods: ["u", "u", "l"],
                                                                   delimiter: " ")
                    
                    let opmlToBody = OPMLtoBody()
                    let (body, title) = opmlToBody.importFrom(fileURL,
                                                              defaultTitle: defaultTitle)
                    _ = note.setTitle(title)
                    _ = note.setBody(body)
                } else if ext == "vcf" {
                    let contacts = ContactCards()
                    let contactNotes = contacts.parse(vCards: fileURL, collection: collection)
                    for contactNote in contactNotes {
                        let addedNote = addPastedNote(contactNote)
                        if addedNote != nil {
                            notesAdded += 1
                            if firstNotePasted == nil {
                                firstNotePasted = addedNote
                            }
                        }
                    }
                } else if row >= 0 && dropOperation == .on && !likelyText {
                    let dropNote = noteIO.getNote(at: row)
                    if dropNote != nil {
                        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                                    note: dropNote,
                                                    position: nil, row: -1, searchPhrase: nil)
                        // select(note: dropNote, position: nil, source: .action, andScroll: true)
                        addAttachment(urlToAttach: fileURL)
                        if firstNotePasted == nil {
                            firstNotePasted = dropNote
                        }
                    }
                } else if dropOperation != .on && !likelyText {
                    let defaultTitle = StringUtils.wordDemarcation(fileName,
                                                        caseMods: ["u", "u", "l"],
                                                        delimiter: " ")
                    _ = note.setTitle(defaultTitle)
                    let localLink = collection.makeLinkRelative(startingLink: fileURL.absoluteString)
                    _ = note.setLink(localLink)
                } else {
                    let addedNote = importTextFile(fileURL: fileURL,
                                                   newLevel: newLevel, newSeq: newSeq, newKlass: newKlass,
                                                   finishUp: false)
                    if addedNote != nil {
                        firstNotePasted = addedNote
                    }
                    continue
                }
            } else if str != nil && str!.count > 0 {
                logInfo(msg: "Processing pasted item as Note")
                attachmentPaths = strToNote(str: str!, note: note, defaultTitle: nil)
            } else {
                logInfo(msg: "Not sure how to handle this pasted item")
            }
            var updateExisting = false
            var existingNote: Note?
            if dropOperation == .above && collection.seqFieldDef != nil {
                existingNote = noteIO.getNote(forID: note.noteID)
                if existingNote != nil {
                    let existingTrimmed = StringUtils.trim(existingNote!.body.value)
                    let dropTrimmed = StringUtils.trim(note.body.value)
                    if existingTrimmed == dropTrimmed {
                        updateExisting = true
                    }
                } else {
                    // printprint("  - could not find an existing note with this id")
                }
            }

            if updateExisting {
                let moved = moveNote(note: existingNote!, row: row)
                if moved != nil {
                    notesAdded += 1
                    if firstNotePasted == nil {
                        firstNotePasted = moved
                    }
                }
            } else {
                if newLevel != nil {
                    _ = note.setLevel(newLevel!)
                }
                if newSeq != nil {
                    _ = note.setSeq(newSeq!.value)
                }
                if newKlass != nil && !note.hasKlass() {
                    _ = note.setKlass(newKlass!.value)
                }
                let addedNote = addPastedNote(note)
                if addedNote != nil {
                    notesAdded += 1
                    if firstNotePasted == nil {
                        firstNotePasted = addedNote
                    }
                    copyAttachments(note: addedNote!, io: noteIO, attachmentPaths: attachmentPaths)
                }
            }
        } // end for each item
        if firstNotePasted != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: firstNotePasted,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: firstNotePasted, position: nil, source: .nav, andScroll: true)
        } else {
            finishBatchOperation()
        }
        return notesAdded
    }
    
    
    /// Given a Note formatted as a String, extract the fields and apply them to the give Note.
    /// - Parameters:
    ///   - str: A String containing a formatted Note.
    ///   - note: The Note to which the extracted fields are to be applied.
    ///   - defaultTitle: The default tile to use, if one is not defined within the passed string.
    /// - Returns: Note attachment paths.
    func strToNote(str: String, note: Note, defaultTitle: String?) -> String {
        var attachmentPaths = ""
        let tempCollection = NoteCollection()
        tempCollection.otherFields = note.collection.otherFields
        note.collection.populateFieldDefs(to: tempCollection)
        // tempCollection.dict.unlock()
        let reader = BigStringReader(str)
        let parser = NoteLineParser(collection: tempCollection, reader: reader)
        var possibleTitle = "Pasted Note"
        if defaultTitle != nil && !defaultTitle!.isEmpty {
            possibleTitle = defaultTitle!
        }
        let tempNote = parser.getNote(defaultTitle: possibleTitle,
                                      allowDictAdds: true,
                                      flexibleFieldAssignment: true)
        if !tempNote.title.value.hasPrefix("Pasted Note")
                || tempNote.hasBody() || tempNote.hasLink() {
            tempNote.copyDefinedFields(to: note)
        }
        if let attachmentsField = tempNote.getField(common: NotenikConstants.attachmentsCommon) {
            attachmentPaths = attachmentsField.value.value
        }
        return attachmentPaths
    }
    
    func copyAttachments(note: Note, io: NotenikIO, attachmentPaths: String) {
        guard let collection = io.collection else { return }
        let paths = attachmentPaths.components(separatedBy: "; ")
        for path in paths {
            var fromURL: URL?
            if #available(macOS 13.0, *) {
                fromURL = URL(filePath: path)
            } else {
               fromURL = URL(string: path)
            }
            if fromURL != nil {
                let piped = path.components(separatedBy: " | ")
                if piped.count >= 2 {
                    let suffix = piped[piped.count - 1]
                    let added = io.addAttachment(from: fromURL!, to: note, with: suffix, move: false)
                    if added {
                        var imageDef: FieldDefinition?
                        var imageField: NoteField?
                        var ext: FileExtension?
                        if suffix.lowercased().contains("dark") && collection.imageDarkFieldDef != nil {
                            imageDef = collection.imageDarkFieldDef
                        } else {
                            imageDef = collection.imageNameFieldDef
                        }
                        if imageDef != nil {
                            imageField = note.getField(def: imageDef!)
                            if imageField == nil || imageField!.value.value.count == 0 {
                                ext = FileExtension(fromURL!.pathExtension)
                                if ext!.isImage {
                                    _ = note.setField(label: imageDef!.fieldLabel.commonForm, value: suffix)
                                    _ = io.writeNote(note)
                                }
                            }
                        }
                    } else {
                        communicateError("Attachment could not be added - possible duplicate", alert: true)
                    }
                }
            }
        }
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
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: addedNote,
                                        position: nil, row: -1, searchPhrase: nil)
            // select(note: addedNote, position: nil, source: .action, andScroll: true)
        }
        return addedNote
    }
    
    func moveNote(note: Note, row: Int) -> Note? {
        guard let noteIO = guardForCollectionAction() else { return nil }
        let collection = noteIO.collection
        let seqDef = collection?.seqFieldDef

        let position = noteIO.positionOfNote(note)
        _ = noteIO.selectNote(at: position.index)
        let modNote = note.copy() as! Note
        let level = note.level
        var priorSeq: SeqValue?
        if seqDef != nil {
            let seqType = seqDef!.fieldType as! SeqType
            priorSeq = seqType.createValue() as? SeqValue
        }
        var priorLevel: LevelValue?
        if row > 0 {
            let priorIndex = row - 1
            let priorNote = noteIO.getNote(at: priorIndex)
            if priorNote != nil {
                priorSeq = priorNote!.seq
                priorLevel = priorNote!.level
            }
        }
        if seqDef != nil {
            let modSeq = priorSeq!.dupe()
            if priorLevel != nil {
                modSeq.incByLevels(originalLevel: priorLevel!, newLevel: level)
            }
            _ = modNote.setSeq(modSeq.value)
        }
        let _ = recordMods(noteIO: noteIO, note: note, modNote: modNote)
        return modNote
    }
    
    func addPastedNote(_ noteToAdd: Note) -> Note? {
        guard !pendingMod else { return nil }
        guard io != nil && io!.collectionOpen else { return nil }
        guard let noteIO = io else { return nil }
        guard noteToAdd.hasTitle() else {
            return nil
        }
        let originalTitle = noteToAdd.title.value
        var keyFound = true
        var dupCount = 1
        while keyFound {
            let id = noteToAdd.noteID.id
            let existingNote = noteIO.getNote(forID: id)
            if existingNote != nil {
                dupCount += 1
                _ = noteToAdd.setTitle("\(originalTitle) \(dupCount)")
                noteToAdd.identify()
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
        guard let collection = noteIO.collection else { return }
        let (note, _) = noteIO.getSelectedNote()
        guard let selNote = note else { return }
        guard collection.dict.contains(collection.linkFieldDef) else { return }

        // Ask the user to pick a local file or folder
        let openPanel = NSOpenPanel()
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
        
        let localFileURL = openPanel.url!
        let localLink = collection.makeLinkRelative(startingLink: localFileURL.absoluteString)
        
        // Now let's make the appropriate updates
        // MultiFileIO.shared.registerBookmark(url: openPanel.url!)
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            let linkOK = editVC!.setLink(localLink)
            if !linkOK {
                communicateError("Link field not found", alert: true)
            }
        } else {
            let setOK = selNote.setLink(localLink)
            if !setOK {
                communicateError("Attempt to set link value for selected note failed!")
            }
            populateEditFields(with: selNote)
            let writeOK = noteIO.writeNote(selNote)
            if !writeOK {
                communicateError("Attempted write of updated note failed!")
            }
            displayModifiedNote(updatedNote: selNote)
            // reloadViews()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: selNote,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: selNote, position: nil, source: .action, andScroll: true)
        }
    }
    
    @IBAction func wikipediaLink(_ sender: Any) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, _) = io!.getSelectedNote()
        guard note != nil else { return }
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.wikipediaLink()
        } else {
            let modNote = note!.copy() as! Note
            _ = modNote.setLink(StringUtils.wikify(note!.title.value))
            let _ = recordMods(noteIO: io!, note: note!, modNote: modNote)
        }
    }
    
    @IBAction func cleanLink(_ sender: Any) {
        if let cleanLinkController = self.linkCleanerStoryboard.instantiateController(withIdentifier: "linkcleanerWC") as? LinkCleanerWindowController {
            cleanLinkController.showWindow(self)
            cleanLinkController.passCollectionWindow(self)
        }
    }
    
    func getDirtyLink() -> String? {
        let (_, sel) = guardForNoteAction()
        guard let selectedNote = sel else { return nil }
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            return editVC!.getLink()
        } else {
            return selectedNote.link.value
        }
    }
    
    /// If we have a text view as a first responder, then paste into it from the clipboard. 
    func pasteTextNow() {
        if let win = window {
            if let first = win.firstResponder {
                if let view = first as? NSTextView {
                    view.paste(self)
                }
            }
        }
    }
    
    func setCleanLink(_ clean: String) {
        guard io != nil && io!.collectionOpen else { return }
        let (note, _) = io!.getSelectedNote()
        guard note != nil else { return }
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            _ = editVC!.setLink(clean)
        } else {
            let modNote = note!.copy() as! Note
            _ = modNote.setLink(clean)
            let _ = recordMods(noteIO: io!, note: note!, modNote: modNote)
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    @IBAction func menuNoteClose(_ sender: Any) {
        
        let (nIO, sNote) = guardForNoteAction()
        guard let io = nIO else { return }
        guard let selNote = sNote else { return }
        
        if noteTabs!.tabView.selectedTabViewItem!.label == "Edit" {
            editVC!.closeNote()
        } else {
            let modNote = selNote.copy() as! Note
            modNote.close()
            let (chgNote, _) = io.modNote(oldNote: selNote, newNote: modNote)
            if chgNote == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                  category: "CollectionWindowController",
                                  level: .fault,
                                  message: "Problems modifying note titled \(selNote.title)")
            } else {
                displayModifiedNote(updatedNote: chgNote!)
                // reloadViews()
                _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                            note: chgNote,
                                            position: nil, row: -1, searchPhrase: nil,
                                            withUpdates: true)
                // select(note: chgNote, position: nil, source: .action)
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
        guard let sequencer = Sequencer(io: noteIO) else { return }
        let (notesInced, firstModNote) = sequencer.incrementSeq(startingNote: note)
        logInfo(msg: "\(notesInced) Notes had their Seq values incremented")
        if firstModNote != nil {
            // displayModifiedNote(updatedNote: firstModNote!)
            // populateEditFields(with: firstModNote!)
            // reloadViews()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: firstModNote!,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: firstModNote!, position: nil, source: .action, andScroll: true)
        } else {
            print("  - first mod note is nil!")
        }
    }
    
    @IBAction func incMajorSeq(_ sender: Any) {
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        guard selNote.hasSeq() else { return }
        guard let sequencer = Sequencer(io: noteIO) else { return }
        
        let (notesInced, firstModNote) = sequencer.incrementSeq(startingNote: selNote, incMajor: true)
        logInfo(msg: "\(notesInced) Notes had their Seq values incremented")
        if firstModNote != nil {
            displayModifiedNote(updatedNote: firstModNote!)
            populateEditFields(with: firstModNote!)
            // reloadViews()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: firstModNote!,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: firstModNote!, position: nil, source: .action, andScroll: true)
        }
    }
    
    @IBAction func indentNote(_ sender: Any) {
        indentBy(1)
    }
    
    @IBAction func outdentNote(_ sender: Any) {
        indentBy(-1)
    }
    
    /// Indent or outdent by the specified number of levels (positive or negative).
    func indentBy(_ indentLevels: Int) {
        
        guard indentLevels != 0 else { return }
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard let ctabs = collectionTabs else { return }
        var lowIndex = -1
        var highIndex = -2
        if ctabs.selectedTabViewItemIndex == 2 && seqOutlineVC != nil {
            (lowIndex, highIndex) = seqOutlineVC!.getRangeOfSelectedNotes(io: noteIO, withClick: false)
        } else {
            (lowIndex, highIndex) = listVC!.getRangeOfSelectedRows()
        }
        guard lowIndex >= 0 else { return }
        guard let selNote = noteIO.getNote(at: lowIndex) else { return }
        
        var newSeq: SeqValue?
        var maxSeqLevel: Int = -1
        if selNote.hasSeq() && lowIndex > 0 {
            let priorNote = noteIO.getNote(at: lowIndex - 1)
            if priorNote != nil && priorNote!.hasSeq() {
                newSeq = priorNote!.seq.dupe()
                maxSeqLevel = selNote.seq.maxLevel
                newSeq!.incAtLevel(level: maxSeqLevel + indentLevels, removingDeeperLevels: true)
            }
        }
        
        // If we're indenting a range of notes, then use the Sequencer.
        if highIndex > lowIndex && newSeq != nil {
            if let sequencer = Sequencer(io: io!) {
                let modStartingNote = sequencer.renumberRange(startingRow: lowIndex, endingRow: highIndex, newSeqValue: newSeq!.value)
                let selCount = highIndex - lowIndex + 1
                seqModified(modStartingNote: modStartingNote, rowCount: selCount, reselect: true)
                return
            }
        }
        
        // Continue with a single Note to indent.
        let modNote = selNote.copy() as! Note
        var noteModified = false
        
        if modNote.hasLevel() {
            let newLevel = modNote.level.dupe()
            newLevel.add(levelsToAdd: indentLevels, config: collection.levelConfig)
            noteModified = modNote.setLevel(newLevel)
        }
        
        if newSeq != nil {
            let seqMod = modNote.setSeq(newSeq!.value)
            if seqMod {
                noteModified = true
            }
        }
        
        if noteModified {
            let (note, position) = noteIO.modNote(oldNote: selNote, newNote: modNote)
            if (note == nil) || (position.invalid) {
                communicateError("Trouble updating Note titled \(modNote.title.value)")
            }
            // reloadViews()
            // select(note: modNote, position: nil, source: .action, andScroll: true)
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: modNote,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
        }
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
        let (chgNote, _) = noteIO.modNote(oldNote: note, newNote: modNote)
        if chgNote == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .error,
                              message: "Problems modifying note titled \(modNote.title)")
            return false
        } else {
            displayModifiedNote(updatedNote: chgNote!)
            // editVC!.populateFields(with: addedNote!)
            editVC!.select(note: chgNote!)
            // reloadViews()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: chgNote,
                                        position: nil, row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: chgNote, position: nil, source: .action, andScroll: true)
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
            var searchPhrase: String?
            if displayVC != nil {
                searchPhrase = displayVC!.searchPhrase
            }
            vc.searchPhrase = searchPhrase
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
        
        let (outcome, _) = modIfChanged()
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
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note,
                                    position: position,
                                    row: -1, searchPhrase: nil)
        // select(note: note, position: position, source: .nav, andScroll: true)
    }
    
    /// Go to the next note in the list
    @IBAction func goToNextNote(_ sender: Any) {
        let (nio, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        guard let noteIO = nio else { return }
        
        let position = noteIO.positionOfNote(selNote)
        var (nextNote, _) = noteIO.nextNote(position)
        if nextNote == nil {
            (nextNote, _) = noteIO.firstNote()
        }
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: nextNote,
                                    position: nil,
                                    row: -1, searchPhrase: nil)
        // select(note: nextNote, position: nil, source: .nav, andScroll: true)
    }
    
    @IBAction func scrollToSelected(_ sender: Any) {
        guard listVC != nil else { return }
        listVC!.scrollToSelectedRow()
    }
    
    /// Go to the prior note in the list
    @IBAction func goToPriorNote(_ sender: Any) {
        
        let (nio, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        guard let noteIO = nio else { return }
        
        if webLinkFollowed && displayVC != nil {
            displayVC!.reload()
            return
        }
        
        let position = noteIO.positionOfNote(selNote)
        var (priorNote, _) = noteIO.priorNote(position)
        if priorNote == nil {
            (priorNote, _) = noteIO.lastNote()
        }
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: priorNote,
                                    position: nil,
                                    row: -1, searchPhrase: nil)
        // select(note: priorNote, position: nil, source: .nav, andScroll: true)
    }
    
    @IBAction func goToRandomNote(_ sender: Any) {
        let (nio, _) = guardForNoteAction()
        guard let noteIO = nio else { return }
        var (randomNote, randomPosition) = noteIO.getSelectedNote()
        guard randomNote != nil else { return }
        let lastTitle = randomNote!.title.value
        var first = 0
        if noteIO.collection!.seqFieldDef != nil {
            let (note, _) = noteIO.firstNote()
            if note != nil && !note!.hasSeq() && noteIO.notesCount > 1 {
                first = 1
            }
        }
        while (noteIO.notesCount - 1) > first && randomNote!.title.value == lastTitle {
            let randomIndex = Int.random(in: first..<noteIO.notesCount)
            randomPosition = NotePosition(index: randomIndex)
            randomNote = noteIO.getNote(at: randomIndex)
            guard randomNote != nil else { return }
        }
        
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: randomNote,
                                    position: randomPosition,
                                    row: -1, searchPhrase: nil)
        // select(note: randomNote, position: randomPosition, source: .nav, andScroll: true)
    }
    
    @IBAction func backwardInHistory(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        
        if webLinkFollowed && displayVC != nil {
            displayVC!.reload()
            return
        }
        
        let priorNote = viewCoordinator.navHistory!.backwards(from: selNote)
        if priorNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: priorNote,
                                        position: nil,
                                        row: -1, searchPhrase: nil)
            // select(note: priorNote, position: nil, source: .nav, andScroll: true)
        } else {
            communicateError("Navigation History Exhausted", alert: true)
        }
    }
    
    @IBAction func forwardInHistory(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        let nextNote = viewCoordinator.navHistory!.forwards(from: selNote)
        if nextNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: nextNote,
                                        position: nil,
                                        row: -1, searchPhrase: nil)
            // select(note: nextNote, position: nil, source: .nav, andScroll: true)
        } else {
            communicateError("Navigation History Exhausted", alert: true)
        }
    }
    
    /// Respond to a user request for an Advanced Search.
    @IBAction func advSearch(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        searcher = SearchNotes(io: noteIO)
        searcher.searchText = searchField.stringValue
        if let advSearchController = self.advSearchStoryboard.instantiateController(withIdentifier: "AdvSearchWC") as? AdvSearchWindowController {
            guard let vc = advSearchController.contentViewController as? AdvSearchViewController else { return }
            advSearchController.showWindow(self)
            vc.window = advSearchController
            vc.noteIO = noteIO
            vc.collectionController = self
            vc.searchOptions = searcher.options
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get an Advanced Search Window Controller!")
        }
    }
    
    @IBAction func selectNote(_ sender: Any) {
        
        guard let noteIO = notenikIO else { return }
        
        guard let notePickerController = self.notePickerStoryboard.instantiateController(withIdentifier: "NotePickerWC") as? NotePickerWindowController else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Note Picker Window Controller!")
            return
        }

        guard let vc = notePickerController.contentViewController as? NotePickerViewController else { return }
        
        notePickerController.showWindow(self)
        vc.collectionController = self
        vc.wc = notePickerController
        vc.noteIO = noteIO
        
        //vc.searchOptions = searchOptions
        // var searchPhrase: String?
        // if displayVC != nil {
            // searchPhrase = displayVC!.searchPhrase
        // }
        // vc.searchPhrase = searchPhrase

    }
    
    @IBAction func dateInsert(_ sender: Any) {
        guard let insertDateController = self.dateInsertStoryboard.instantiateController(withIdentifier: "dateInsertWC") as? DateInsertWindowController else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Date Insert Window Controller")
            return
        }
        guard let vc = insertDateController.contentViewController as? DateInsertViewController else { return }
        insertDateController.showWindow(self)
        vc.collectionController = self
        vc.wc = insertDateController
    }
    
    @IBAction func queryBuilder(_ sender: Any) {
        guard let queryBuilderController = self.queryBuilderStoryboard.instantiateController(withIdentifier: "queryWC") as? QueryBuilderWindowController else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get a Query Builder Window Controller")
            return
        }
        guard let vc = queryBuilderController.contentViewController as? QueryBuilderViewController else { return }
        vc.io = notenikIO
        vc.collectionWC = self
        queryBuilderController.showWindow(self)
        vc.windowController = queryBuilderController
    }
    
    /// Start an Advanced Search using the options provided by the user.
    /// - Parameter options: The options as specified by the user.
    func advSearchNow(options: SearchOptions) {
        searcher.options = options
        self.searchField.stringValue = options.searchText
        searchUsingOptions()
    }
    
    /// Respond to the Find command.
    /// - Parameter sender: The control that triggered this method.
    @IBAction func findNote(_ sender: Any) {
        guard let confirmedWindow = self.window else { return }
        confirmedWindow.makeFirstResponder(searchField)
    }
    
    /// Search for the first matching Note using the search field.
    /// - Parameter sender: The Search field.
    @IBAction func searchNow(_ sender: Any) {
        guard let searchField = sender as? NSSearchField else { return }
        applyCheckBoxUpdates()
        searcher.searchText = searchField.stringValue
        searchUsingOptions()
    }
    
    func searchUsingOptions() {
        guard searcher.hasText else { return }
        guard guardForCollectionAction() != nil else { return }
        let (note, position) = searcher.nextMatching(startNew: true)

        if note != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: position,
                                        row: -1,
                                        searchPhrase: searcher.searchText)
            /* select(note: note,
                   position: position,
                   source: .action,
                   andScroll: true,
                   searchPhrase: searcher.searchText) */
        } else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "No Note found containing search string '\(searcher.searchText)'"
            alert.informativeText = "Searched for match using current advanced options"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
        }
    }
    
    @IBAction func searchForNext(_ sender: Any) {
        searcher.checkUserInput(str: searchField.stringValue)
        guard searcher.hasText else {
            return
        }
        guard let noteIO = guardForCollectionAction() else {
            return
        }
        let (note, position) = searcher.nextMatching(startNew: false)

        if note != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: position,
                                        row: -1, searchPhrase: searcher.searchText)
            /* select(note: note,
                   position: position,
                   source: .action,
                   andScroll: true,
                   searchPhrase: searcher.searchText) */
        } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "No further notes found containing search string '\(searcher.searchText)'"
            alert.informativeText = "Searched for match using current advanced options"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            let (startingNote, startingPosition) = searcher.backToStart()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: startingNote,
                                        position: startingPosition,
                                        row: -1, searchPhrase: nil)
            // select(note: startingNote, position: startingPosition, source: .action, andScroll: true)
            _ = noteIO.selectNote(at: startingPosition.index)
        }
    }
    
    @IBAction func searchForPrevious(_ sender: Any) {
        if !searchField.stringValue.isEmpty && searchField.stringValue != searcher.searchText {
            searcher.searchText = searchField.stringValue
        }
        guard searcher.hasText else { return }
        guard let noteIO = guardForCollectionAction() else { return }
        let note = searcher.searchForPrevious()
        if note != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: nil,
                                        row: -1, searchPhrase: nil)
            /* select(note: note,
                   position: nil,
                   source: .action,
                   andScroll: true,
                   searchPhrase: searcher.searchText) */
        } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "No prior notes found containing search string '\(searcher.searchText)'"
            alert.informativeText = "Searched for match using current advanced options"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            let (startingNote, startingPosition) = searcher.backToStart()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: startingNote,
                                        position: startingPosition,
                                        row: -1, searchPhrase: nil)
            // select(note: startingNote, position: startingPosition, source: .action, andScroll: true)
            _ = noteIO.selectNote(at: startingPosition.index)
        }
    }
    
    func selectNoteTitled(_ title: String) {
        guard let noteIO = guardForCollectionAction() else { return }
        
        let id = StringUtils.toCommon(title)
        guard let note = noteIO.getNote(forID: id) else { return }
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note,
                                    position: nil,
                                    row: -1, searchPhrase: nil)
        // select(note: note, position: nil, source: .action, andScroll: true, searchPhrase: nil)
    }
    
    
    /// Select the first Note in the list. 
    func selectFirstNote() {
        guard let noteIO = guardForCollectionAction() else { return }
        let (firstNote, firstPosition) = noteIO.firstNote()
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: firstNote,
                                    position: firstPosition,
                                    row: -1, searchPhrase: nil)
        // select(note: firstNote, position: firstPosition, source: .nav, andScroll: true)
    }
    
    /// React to the selection of a note, coordinating the various views as needed.
    ///
    /// - Parameters:
    ///   - note:     A note, if we know which one has been selected.
    ///   - position: A position in the collection, if we know what it is.
    ///   - source:   An indicator of the source of the selection; if one of the views
    ///               being coordinated is the source, then we don't need to modify it.
    /*
    func select(note: Note?,
                position: NotePosition?,
                source: NoteSelectionSource,
                andScroll: Bool = false,
                searchPhrase: String? = nil) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        
        scroller = NoteScroller(collection: notenikIO!.collection!)
        
        var noteToUse: Note? = note
        var positionToUse: NotePosition? = position
        
        if note != nil && (position == nil || position!.invalid) {
            positionToUse = notenikIO!.positionOfNote(note!)
        }
        
        if note == nil && position != nil && position!.valid {
            noteToUse = notenikIO!.getNote(at: position!.index)
        }
        
        if listVC != nil && source != .list && positionToUse != nil && positionToUse!.index >= 0 {
            listVC!.selectRow(index: positionToUse!.index, andScroll: andScroll, checkForMods: (source != .action))
        }
        guard noteToUse != nil else { return }
        
        if displayVC != nil {
            displayVC!.display(note: noteToUse!, io: notenikIO!, searchPhrase: searchPhrase)
        }
        if editVC != nil {
            editVC!.select(note: noteToUse!)
        }
        adjustAttachmentsMenu(noteToUse!)
        
        viewCoordinator.navHistory!.addToHistory(another: noteToUse!)
    } */
    
    /// Adjust the Attachments menu based on the attachments found in the passed note.
    func adjustAttachmentsMenu(_ possibleNote: Note?) {
        
        let topItem = attachmentsMenu.item(at: 0)
        if possibleNote == nil {
            topItem!.title = "attach..."
        } else if possibleNote!.attachments.count > 0 {
            topItem!.title = "files: "
        } else {
            topItem!.title = "attach..."
        }
        
        var i = attachmentsMenu.numberOfItems - 1
        while i > 0 {
            attachmentsMenu.removeItem(at: i)
            i -= 1
        }
        
        guard let note = possibleNote else { return }
        
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
    
    func openAttachment(titled: String) {
        let (_, sel) = guardForNoteAction()
        guard let selNote = sel else { return }
        
        let attachmentURL = selNote.getURLforAttachment(attachmentName: titled)
        
        if attachmentURL != nil {
            let goodOpen = NSWorkspace.shared.open(attachmentURL!)
            if !goodOpen {
                communicateError("Trouble opening attachment at \(attachmentURL!.absoluteString)", alert: true)
            }
        } else {
            communicateError("Trouble opening selected attachment", alert: true)
        }
    }
    
    @IBAction func convertLocalLinkToAttachment(_ sender: Any) {
        
        // See if we're ready to take action
        let (_, sel1) = guardForNoteAction()
        guard let selNote = sel1 else { return }
        
        guard let fileURL = selNote.linkAsURL else { return }
        addAttachment(urlToAttach: fileURL, clearLink: true)
    }
    
    /// Prompt the user for an attachment to add and then copy it to the files folder.
    func addAttachment() {
        // Ask the user for a location on disk
        let openPanel = NSOpenPanel();
        openPanel.title = "Select an attachment for this Note"
        var parent = io!.collection!.fullPathURL!.deletingLastPathComponent()
        if let lastParent = io?.collection?.lastAttachmentParent {
            parent = lastParent
        }
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
        io!.collection!.lastAttachmentParent = urlToAttach.deletingLastPathComponent()
        addAttachment(urlToAttach: urlToAttach)
    }
    
    func addAttachment(urlToAttach: URL, clearLink: Bool = false) {
        let (nio, sel) = guardForNoteAction()
        guard let _ = nio, let selNote = sel else { return }
        guard selNote.noteID.getBaseFilename() != nil else { return }
        let noteLib: ResourceLibrary = selNote.getResourceLib()
        let filesFolderResource = noteLib.ensureResource(type: .attachments)
        guard filesFolderResource.isAvailable else { return }
        if let attachmentController = self.attachmentStoryboard.instantiateController(withIdentifier: "attachmentWC") as? AttachmentWindowController {
            attachmentController.vc.master = self
            attachmentController.vc.setFileToCopy(urlToAttach)
            attachmentController.vc.setStorageFolder(filesFolderResource.actualPath)
            attachmentController.vc.setNote(selNote)
            attachmentController.vc.setClearLinkOption(clearLink)
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
    ///   - move: Should the file be moved instead of copied?
    ///
    func okToAddAttachment(note: Note, file: URL, suffix: String, move: Bool, clearLink: Bool = false) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        let added = noteIO.addAttachment(from: file, to: note, with: suffix, move: move)
        var noteUpdates = false
        if added {
            adjustAttachmentsMenu(note)
            noteUpdates = true
            var imageDef: FieldDefinition?
            if suffix.lowercased().contains("dark") && collection.imageDarkFieldDef != nil {
                imageDef = collection.imageDarkFieldDef
            } else {
                imageDef = collection.imageNameFieldDef
            }
            if imageDef != nil {
                let imageField = note.getField(def: imageDef!)
                if imageField == nil || imageField!.value.value.count == 0 {
                    let ext = FileExtension(file.pathExtension)
                    if ext.isImage {
                        _ = note.setField(label: imageDef!.fieldLabel.commonForm, value: suffix)
                        noteUpdates = true
                    }
                }
            }
            if clearLink {
                _ = note.setLink("")
                noteUpdates = true
            }
            if noteUpdates {
                _ = noteIO.writeNote(note)
                displayModifiedNote(updatedNote: note)
                populateEditFields(with: note)
                reloadViews()
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
        
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        applyCheckBoxUpdates()
        
        newNoteRequested = true
        newNote = Note(collection: notenikIO!.collection!)
        adjustAttachmentsMenu(nil)
        scroller = NoteScroller(collection: notenikIO!.collection!)
        
        setFollowing()
        
        populateEditFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    func setFollowing() {
        guard let io = notenikIO else { return }
        guard io.collectionOpen else { return }
        guard let collection = io.collection else { return }
        guard collection.seqFieldDef != nil else { return }
        let (selection, _) = io.getSelectedNote()
        guard let sel = selection else { return }
        guard let following = newNote else { return }
        
        if following.collection.seqFieldDef != nil && sel.hasSeq()
                && (collection.sortParm == .seqPlusTitle || collection.sortParm == .tasksBySeq) {
            let incSeq = sel.seq.dupe()
            incSeq.increment()
            _ = following.setSeq(incSeq.value)
        }
        
        if following.collection.levelFieldDef != nil && sel.hasLevel() && !following.hasLevel() {
            _ = following.setLevel(sel.level.value)
        }
    }
    
    /// Duplicate the Selected Note
    @IBAction func duplicateNote(_ sender: Any) {
        
        guard notenikIO != nil && notenikIO!.collectionOpen else { return }
        let (selectedNote, _) = notenikIO!.getSelectedNote()
        guard selectedNote != nil else { return }
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return }
        applyCheckBoxUpdates()
        duplicateNote(startingNote: selectedNote!)
    }
    
    /// Duplicate the passed Note. 
    func duplicateNote(startingNote: Note) {
        guard let noteIO = guardForCollectionAction() else { return }
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        populateEditFields(with: startingNote)
        noteTabs!.tabView.selectLastTabViewItem(self)
    }
    
    func newChild(parent: Note) {

        guard let noteIO = guardForCollectionAction() else { return }
        
        newNoteRequested = true
        newNote = Note(collection: noteIO.collection!)
        
        if parent.hasLevel() {
            let parentLevel = parent.level.getInt()
            let childLevel = parentLevel + 1
            _ = newNote!.setLevel(childLevel)
        }
        
        if parent.hasSeq() {
            let incSeq = parent.seq.dupe()
            let incLevel = parent.seq.maxLevel + 1
            incSeq.incAtLevel(level: incLevel, removingDeeperLevels: false)
            _ = newNote!.setSeq(incSeq.value)
        }
        
        populateEditFields(with: newNote!)
        noteTabs!.tabView.selectTabViewItem(at: 1)
        guard let window = self.window else { return }
        guard let titleView = editVC?.titleView else { return }
        window.makeFirstResponder(titleView.view)
    }
    
    /// Present the user with a confirmation dialog.
    /// - Parameter msg: The warning to be presented to the user.
    /// - Returns: True for OK to proceed; false otherwise.
    func confirmAction(msg: String, info: String? = nil) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = msg
        if let infoText = info {
            if !infoText.isEmpty {
                alert.informativeText = infoText
            }
        }
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
    
    func deleteRangeOfNotes(startingRow: Int, endingRow: Int) {
        guard let noteIO = guardForCollectionAction() else { return }
        let deleteCount = endingRow - startingRow + 1
        guard let firstNote = noteIO.getNote(at: startingRow) else { return }
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Really Delete \(deleteCount) Notes starting with Note titled \(firstNote.title.value)?"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        guard noteIO.notesCount - deleteCount >= 1 else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "A Notenik Collection always needs to have at least one Note"
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
            return
        }
        
        var i = startingRow
        var notesLeftToDelete = deleteCount
        while notesLeftToDelete > 0 {
            guard let noteToDelete = noteIO.getNote(at: i) else {
                i += 1
                notesLeftToDelete -= 1
                continue
            }
            pendingEdits = false
            if undoMgr != nil {
                let undoNote = noteToDelete.copy() as! Note
                undoMgr!.registerUndo(withTarget: self) {
                    targetSelf in targetSelf.restoreNote(undoNote)
                }
                undoMgr!.setActionName("Delete Note")
            }
            _ = noteIO.deleteNote(noteToDelete, preserveAttachments: false)
            notesLeftToDelete -= 1
        }
        // reloadViews()
        var selNote: Note?
        if i < noteIO.notesCount {
            selNote = noteIO.getNote(at: i)
        }
        if selNote == nil {
            selNote = noteIO.getNote(at: startingRow - 1)
        }
        if selNote == nil {
            (selNote, _) = noteIO.firstNote()
        }
        if selNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: selNote,
                                        position: nil,
                                        row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: selNote, position: nil, source: .action, andScroll: true)
        }
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
        guard proceed else { return }

        pendingEdits = false
        if undoMgr != nil {
            let undoNote = selectedNote.copy() as! Note
            undoMgr!.registerUndo(withTarget: self) {
                targetSelf in targetSelf.restoreNote(undoNote)
            }
            undoMgr!.setActionName("Delete Note")
        }
        let (nextNote, nextPosition) = noteIO.deleteSelectedNote(preserveAttachments: false)
        // reloadViews()
        if nextNote != nil {
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: nextNote,
                                        position: nextPosition,
                                        row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: nextNote, position: nextPosition, source: .action, andScroll: true)
        }
    }
    
    
    func restoreNote(_ note: Note) {
        let noteIO = guardForCollectionAction()
        if noteIO == nil { return }
        undoMgr!.registerUndo(withTarget: self) {
            targetSelf in targetSelf.redoDelete(note)
        }
        _ = addNewNote(note)
    }
    
    func redoDelete(_ note: Note) {
        let noteIO = guardForCollectionAction()
        if noteIO == nil { return }
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note,
                                    position: nil,
                                    row: -1, searchPhrase: nil)
        // select(note: note, position: nil, source: .action, andScroll: true, searchPhrase: nil)
        deleteNote(self)
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
        
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Proceed with the Discard of your current edits?"
        alert.informativeText = "(All of your current entries on the Edit tab will be lost.)"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        pendingMod = false
        pendingEdits = false
        if newNoteRequested {
            newNoteRequested = false
            let (note, position) = io!.firstNote()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: position,
                                        row: -1, searchPhrase: nil)
            // select(note: note, position: position, source: .action, andScroll: true)
        } else {
            let (note, _) = io!.getSelectedNote()
            guard note != nil else { return }
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: nil,
                                        row: -1, searchPhrase: nil)
            // select(note: note, position: nil, source: .action, andScroll: true)
        }
        noteTabs!.tabView.selectFirstTabViewItem(nil)
    }
    
    @IBAction func openEdits(_ sender: Any) {
        guard noteTabs!.tabView.selectedTabViewItem!.label != "Edit"  else { return }
        let (_, sel) = guardForNoteAction()
        guard sel != nil else { return }
        editVC!.refreshLookupData()
        noteTabs!.tabView.selectTabViewItem(at: 1)
    }
    
    @IBAction func saveEdits(_ sender: Any) {
        if !pendingMod {
            let _ = modIfChanged()
            applyCheckBoxUpdates()
        }
    }
    
    /// Modify the Note if the user changed anything on the Edit Screen
    func modIfChanged() -> (modIfChangedOutcome, Note?) {
        guard editVC != nil else { return (.notReady, nil) }
        guard !pendingMod else {
            checkForPromises()
            return (.notReady, nil)
        }
        guard newNoteRequested || pendingEdits else {
            checkForPromises()
            return (.noChange, nil)
        }
        pendingMod = true
        let (outcome, note) = editVC!.modIfChanged(newNoteRequested: newNoteRequested, newNote: newNote)
        if outcome != .tryAgain {
            newNoteRequested = false
        }
        if outcome != .tryAgain && outcome != .noChange {
            pendingEdits = false
        }
        if outcome == .add || outcome == .modWithKeyChanges || outcome == .modify {
            populateEditFields(with: note!)
        }
        
        // Update directions, if requested.
        if outcome == .add || outcome == .modWithKeyChanges || outcome == .modify {
            
            // Update driving direcetions if needed
            if let directionsDef = io?.collection?.directionsFieldDef {
                if let directionsField = note!.getField(def: directionsDef) {
                    if let value = directionsField.value as? DirectionsValue {
                        if value.directionsRequested {
                            var source: AddressValue? = nil
                            var dest:   AddressValue? = nil
                            let position = io!.positionOfNote(note!)
                            if note!.hasAddress() {
                                dest = note!.address
                            } else {
                                var nextNote: Note?
                                var nextPosition: NotePosition?
                                (nextNote, nextPosition) = io!.nextNote(position)
                                while dest == nil && nextNote != nil {
                                    if nextNote!.hasAddress() {
                                        dest = nextNote!.address
                                    } else {
                                        (nextNote, nextPosition) = io!.nextNote(nextPosition!)
                                    }
                                }
                            }
                            var priorNote: Note?
                            var priorPostion: NotePosition?
                            (priorNote, priorPostion) = io!.priorNote(position)
                            while source == nil && priorNote != nil {
                                if priorNote!.hasAddress() {
                                    source = priorNote!.address
                                } else {
                                    (priorNote, priorPostion) = io!.priorNote(priorPostion!)
                                }
                            }
                            value.set(source: source, destination: dest)
                            _ = io!.writeNote(note!)
                        }
                    }
                }
            }
        }
        
        if outcome == .add || outcome == .modWithKeyChanges {
            // reloadViews()
            _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                        note: note,
                                        position: nil,
                                        row: -1, searchPhrase: nil,
                                        withUpdates: true)
            // select(note: note, position: nil, source: .action, andScroll: true)
            if note != nil {
                mirrorNote(note!)
            }
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome == .modify {
            displayModifiedNote(updatedNote: note!)
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        } else if outcome != .tryAgain {
            displayVC!.scroll()
            noteTabs!.tabView.selectFirstTabViewItem(nil)
        }
        pendingMod = false
        if outcome == .add || outcome == .modWithKeyChanges || outcome == .modify {
            checkForReviewRequest()
        }
        checkForPromises()
        return (outcome, note)
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
    
    /// Backup the Collection to a Zip file.
    @IBAction func backupToZip(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let nowStr = formatter.string(from: now)
        let defaultName = "\(noteIO.collection!.title) backup on \(nowStr).zip"
        
        let savePanel = NSSavePanel();
        savePanel.title = "Specify an output file"
        let parent = io!.collection!.fullPathURL
        savePanel.directoryURL = parent
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = defaultName
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            let zipPath = savePanel.url!.path
            SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: noteIO.collection!.fullPath)
            communicateSuccess("Backup file generated", info: "At \(zipPath)", alert: true)
        }
    }
    
    @IBAction func makeCollectionEssential(_ sender: Any) {
        juggler.makeCollectionEssential(io: notenikIO!)
    }
    
    @IBAction func normalizeCollection(_ sender: Any) {
        reloadCollection(sender)
        guard let noteIO = guardForCollectionAction() else { return }
        var updated = 0
        var (note, position) = noteIO.firstNote()
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
    
    @IBAction func showFolderInFinder(_ sender: Any) {
        guard let nnkIO = guardForCollectionAction() else { return }
        let folderPath = nnkIO.collection!.lib.getPath(type: .collection)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderPath)
    }
    
    /// Reload the current collection from disk
    @IBAction func reloadCollection(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let path = noteIO.collection!.fullPath
        let readOnly = noteIO.collection!.readOnly
        saveBeforeClose()
        noteIO.closeCollection()
        newNoteRequested = false
        pendingMod = false
        pendingEdits = false
        
        let (_, newIO) = multi.provision(collectionPath: path, inspector: nil, readOnly: readOnly)
        
        self.io = newIO
    }
    
    /// Open the current Note in the user's preferred text editor.
    @IBAction func textEditNote(_ sender: Any) {
        let (_, sel) = guardForNoteAction()
        guard let noteToUse = sel else { return }
        if noteToUse.noteID.hasData {
            NSWorkspace.shared.openFile(noteToUse.noteID.getFullPath(note: noteToUse)!)
        }
    }
    
    /// Reload the currently selected note from disk.
    @IBAction func reloadNote(_ sender: Any) {
        let (nio, sel) = guardForNoteAction()
        guard let noteIO = nio, let selNote = sel else { return }
        guard let reloaded = noteIO.reloadNote(selNote) else { return }
        // reloadViews()
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: reloaded,
                                    position: nil,
                                    row: -1, searchPhrase: nil,
                                    withUpdates: true)
        // select(note: reloaded, position: nil, source: .action, andScroll: true)
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
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code adjusts sort options.
    //
    // ----------------------------------------------------------------------------------
    
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
    
    @IBAction func sortByDateModified(_ sender: Any) {
        setSortParm(.dateModified)
    }
    
    @IBAction func sortByDateAndSeq(_ sender: Any) {
        setSortParm(.datePlusSeq)
    }
    
    @IBAction func sortByRankAndSeq(_ sender: Any) {
        setSortParm(.rankSeqTitle)
    }
    
    @IBAction func sortByKlassAndTitle(_ sender: Any) {
        setSortParm(.klassTitle)
    }
    
    @IBAction func sortByKlassDateAndTitle(_ sender: Any) {
        setSortParm(.klassDateTitle)
    }
    
    @IBAction func sortByFolderAndTitle(_ sender: Any) {
        setSortParm(.folderTitle)
    }
    
    @IBAction func sortByFolderDateAndTitle(_ sender: Any) {
        setSortParm(.folderDateTitle)
    }
    
    @IBAction func sortByFolderSeqAndTitle(_ sender: Any) {
        setSortParm(.folderSeqTitle)
    }
    
    @IBAction func sortByLastNameFirst(_ sender: Any) {
        setSortParm(.lastNameFirst)
    }
    
    @IBAction func sortReverse(_ sender: NSMenuItem) {
        guard let io = notenikIO else { return }
        if io.sortDescending {
            setSortDescending(false)
        } else {
            setSortDescending(true)
        }
    }
    
    @IBAction func sortDates(_ sender: NSMenuItem) {
        guard let io = notenikIO else { return }
        if io.sortBlankDatesLast {
            setSortBlankDatesLast(false)
        } else {
            setSortBlankDatesLast(true)
        }
    }
    
    func setSortParm(_ sortParm: NoteSortParm) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortParm = sortParm
        noteIO.sortDescending = false
        searcher.scope = .all
        lister.setSortParm(sortParm)
        noteIO.persistCollectionInfo()
        juggler.updateSortMenu()
    }
    
    func setSortDescending(_ descending: Bool) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortDescending = descending
        searcher.scope = .all
        lister.setSortDescending(descending)
        noteIO.persistCollectionInfo()
        juggler.updateSortMenu()
    }
    
    func setSortBlankDatesLast(_ sortBlankDatesLast: Bool) {
        guard var noteIO = notenikIO else { return }
        guard let lister = listVC else { return }
        noteIO.sortBlankDatesLast = sortBlankDatesLast
        lister.setDateSort(sortBlankDatesLast)
        noteIO.persistCollectionInfo()
        juggler.updateSortMenu()
    }
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code adjusts the display mode.
    //
    // ----------------------------------------------------------------------------------
    
    @IBAction func setDisplayToNormal(_sender: Any) {
        setDisplayTo(.normal)
    }
    
    @IBAction func setDisplayToStreamlined(_sender: Any) {
        setDisplayTo(.streamlinedReading)
    }
    
    @IBAction func setDisplayToPresentation(_sender: Any) {
        setDisplayTo(.presentation)
    }
    
    @IBAction func setDisplayToQuotes(_sender: Any) {
        setDisplayTo(.quotations)
    }
    
    @IBAction func setDisplayToCustom(_sender: Any) {
        setDisplayTo(.custom)
    }
    
    func setDisplayTo(_ displayMode: DisplayMode) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        if !collection.displayTemplate.isEmpty {
            collection.displayMode = displayMode
            if displayMode == .custom {
                collection.overrideCustomDisplay = false
            } else {
                collection.overrideCustomDisplay = true
            }
        } else {
            collection.overrideCustomDisplay = false
            if displayMode == .custom {
                collection.displayMode = .normal
                communicateError("No Custom Display Template Was Found", alert: true)
            } else {
                collection.displayMode = displayMode
            }
        }
        noteIO.persistCollectionInfo()
        reloadCollection(self)
    }
    
    @IBAction func togglePresentationMode(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        switch collection.displayMode {
        case .normal:
            collection.displayMode = .streamlinedReading
        case .presentation:
            collection.displayMode = .quotations
        case .streamlinedReading:
            collection.displayMode = .presentation
        case .quotations:
            collection.displayMode = .normal
        case .custom:
            collection.displayMode = .normal
        }
        noteIO.persistCollectionInfo()
        reloadCollection(self)
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
                    MultiFileIO.shared.registerBookmark(url: openPanel.url!)
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
        // reloadViews()
        let (note, position) = io!.firstNote()
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note,
                                    position: position,
                                    row: -1, searchPhrase: nil,
                                    withUpdates: true)
        // select(note: note, position: position, source: .nav, andScroll: true)
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "\(purgeCount) Notes purged from the Collection"
        if archiveURL != nil {
            alert.informativeText = "Archived to \(archiveURL!.path)"
        }
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    var importParms = ImportParms()
    
    /// Import additional notes from a comma- or tab-separated text file.
    @IBAction func importDelimited(_ sender: Any) {
        
        importParms = ImportParms()
        importParms.format = .delim
        importWithParms()
    }
    
    /// Import the notes from another Notenik Collection
    @IBAction func importNotenik(_ sender: Any) {
        importParms = ImportParms()
        importParms.format = .notenik
        importWithParms()
    }
    
    func importWithParms() {
        guard let noteIO = guardForCollectionAction() else { return }
        
        if let importController = self.importStoryboard.instantiateController(withIdentifier: "importWC") as? ImportWindowController {
            importController.collectionWC = self
            importController.io = noteIO
            importController.parms = importParms
            importController.showWindow(self)
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .fault,
                              message: "Couldn't get an Import Window Controller!")
        }
    }
    
    /// User has finished with import settings.
    func importSettingsObtained() {
        if importParms.userOkToSettings {
            switch importParms.format {
            case .delim:
                importDelimitedOK()
            case .notenik:
                importNotenikOK()
            default:
                break
            }
        }
    }
    
    /// User said to go ahead and import. 
    func importDelimitedOK() {
        
        guard let noteIO = guardForCollectionAction() else { return }
        
        guard let importURL = promptUserForImportFile(
                title: "Open an input tab- or comma-separated text file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        importDelimitedFromURL(importURL, noteIO: noteIO)
    }
    
    func importDelimitedFromURL(_ fileURL: URL, noteIO: NotenikIO) {
        let importer = DelimitedReader()
        let (imports, mods) = noteIO.importRows(importer: importer, fileURL: fileURL, importParms: importParms)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes, modified \(mods) notes, from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes, modified \(mods) notes, from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    func importNotenikOK() {
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        // Ask the user for an import location
        let openPanel = juggler.prepCollectionOpenPanel()
        openPanel.canCreateDirectories = false
        if let parent = noteIO.collection?.getLastImportParent() {
            openPanel.directoryURL = parent
        }
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }

        let importIO: NotenikIO = FileIO()
        let importRealm = importIO.getDefaultRealm()
        let importURL = openPanel.url!
        importRealm.path = ""
        let importCollection = importIO.openCollection(realm: importRealm,
                                                       collectionPath: importURL.path,
                                                       readOnly: true,
                                                       multiRequests: nil)
        guard importCollection != nil else {
            blockingAlert(msg: "The import location does not seem to be a valid Notenik Collection",
                          info: "Attempted to import from \(importURL.path)")
            return
        }

        let importer = NotenikImporter(parms: importParms, importIO: importIO, updateIO: noteIO)
        importer.importNotes()
        importParms.logTotals()
        
        let ok = (importParms.added > 0 || importParms.modified > 0)
        if ok {
            noteIO.collection!.setLastImportParent(url: importURL.deletingLastPathComponent())
        }
        informUserOfImportExportResults(operation: "import", ok: ok, numberOfNotes: importParms.input, path: importURL.path)
        
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
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL, importParms: importParms)
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
        let imports = noteIO.importRows(importer: importer, fileURL: fileURL, importParms: importParms)
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
        let (imports, mods) = noteIO.importRows(importer: importer, fileURL: fileURL, importParms: importParms)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionWindowController",
                          level: .info,
                          message: "Imported \(imports) notes, Modified \(mods) notes, from \(fileURL.path)")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Imported \(imports) notes, Modified \(mods) notes, from \(fileURL.path)"
        alert.addButton(withTitle: "OK")
        _ = alert.runModal()
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importTextFile(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Import an input Text file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        _ = importTextFile(fileURL: importURL, newLevel: nil, newSeq: nil, newKlass: nil)
    }
    
    @IBAction func importFolderOfTextFiles(_ sender: Any) {
        importFolderOfTextFiles2()
    }
    
    func importFolderOfTextFiles1() {
        guard let noteIO = guardForCollectionAction() else { return }
        
        let openPanel = NSOpenPanel();
        openPanel.title = "Select Folder of Text Files to Import"
        openPanel.directoryURL = noteIO.collection!.lib.getURL(type: .parent)
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }
        guard let importURL = openPanel.url else { return }
        
        var imported = 0
        var rejected = 0
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: importURL.path)
            for item in contents {
                let resource = ResourceFileSys(folderPath: importURL.path, fileName: item)
                if resource.type == .note {
                    let addedNote = importTextFile(fileURL: resource.url!,
                                                   newLevel: nil, newSeq: nil, newKlass: nil,
                                                   finishUp: false)
                    if addedNote == nil {
                        rejected += 1
                    } else {
                        imported += 1
                    }
                }
                /*
                if item.starts(with: ".") {
                    continue
                }
                let fileURL = importURL.appendingPathComponent(item)
                if ResourceFileSys.isLikelyNoteFile(fileURL: fileURL, preferredNoteExt: nil) {
                    let addedNote = importTextFile(fileURL: fileURL,
                                                   newLevel: nil, newSeq: nil, newKlass: nil,
                                                   finishUp: false)
                    if addedNote == nil {
                        rejected += 1
                    } else {
                        imported += 1
                    }
                } */
            }
        } catch {
            communicateError("Problems reading contents of directory at \(importURL)", alert: true)
        }
        
        let ok = (rejected == 0) && (imported > 0)
        informUserOfImportExportResults(operation: "import", ok: ok, numberOfNotes: imported, path: importURL.path)
        finishBatchOperation()
    }
    
    /// Import the notes from another Notenik Collection
    func importFolderOfTextFiles2() {

        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        guard let collection = noteIO.collection else { return }
        
        // Ask the user for an import location
        let openPanel = juggler.prepCollectionOpenPanel()
        openPanel.canCreateDirectories = false
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }

        let importIO: NotenikIO = FileIO()
        let importRealm = importIO.getDefaultRealm()
        let importURL = openPanel.url!
        importRealm.path = ""
        let importCollection = importIO.openCollection(realm: importRealm,
                                                       collectionPath: importURL.path,
                                                       readOnly: true,
                                                       multiRequests: nil)
        guard importCollection != nil else {
            blockingAlert(msg: "The import location does not seem to be a valid Notenik Collection",
                          info: "Attempted to import from \(importURL.path)")
            return
        }

        // OK, let's import
        let lockStart = collection.dict.isLocked
        collection.dict.unlock()
        var imported = 0
        var rejected = 0
        var (importNote, importPosition) = importIO.firstNote()
        while importNote != nil && importPosition.valid {
            let noteCopy = Note(collection: collection)
            importNote!.copyDefinedFields(to: noteCopy, addDefs: true)
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
        
        if lockStart {
            collection.dict.lock()
        }
        
        if rejected > 0 {
            blockingAlert(msg: "\(rejected) Notes could not be imported", info: "See the Log Window for details")
        }
        let ok = imported > 0
        informUserOfImportExportResults(operation: "import", ok: ok, numberOfNotes: imported, path: importURL.path)
        
        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    /// Try to import a new Note from an existing text file.
    func importTextFile(fileURL: URL,
                        newLevel: LevelValue?,
                        newSeq: SeqValue?,
                        newKlass: KlassValue?,
                        finishUp: Bool = true) -> Note? {
        
        guard let noteIO = guardForCollectionAction() else { return nil }
        guard let collection = noteIO.collection else { return nil }
        let newNote = Note(collection: collection)
        
        guard let reader = BigStringReader(fileURL: fileURL) else {
            communicateError("Could not read contents of \(fileURL)")
            return nil
        }
        
        let defaultTitle = fileURL.deletingPathExtension().lastPathComponent
        
        _ = strToNote(str: reader.bigString, note: newNote, defaultTitle: defaultTitle)

        if newLevel != nil {
            _ = newNote.setLevel(newLevel!)
        }
        if newSeq != nil {
            _ = newNote.setSeq(newSeq!.value)
        }
        if newKlass != nil && !newNote.hasKlass() {
            _ = newNote.setKlass(newKlass!.value)
        }
        
        var addedNote: Note?
        if finishUp {
            addedNote = addNewNote(newNote)
        } else {
            addedNote = addPastedNote(newNote)
        }
        if addedNote == nil {
            communicateError("Could not add new Note titled \(newNote.title.value)", alert: true)
        }
        return addedNote
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
    
    @IBAction func importContacts(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input vCard file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }

        let importer = ContactCards()
        let imports = importer.importCards(vCards: importURL, noteIO: noteIO)
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
    
    @IBAction func importOPMLusingSeqAndLevel(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input OPML file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }

        let importer = OPMLImporter(io: noteIO)
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
    
    @IBAction func importOPMLusingHeadings(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input OPML file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        
        let note = Note(collection: collection)

        let fileName = importURL.deletingPathExtension().lastPathComponent
 
        let defaultTitle = StringUtils.wordDemarcation(fileName,
                                            caseMods: ["u", "u", "l"],
                                            delimiter: " ")
        
        let opmlToBody = OPMLtoBody()
        let (body, title) = opmlToBody.importFrom(importURL,
                                                  defaultTitle: defaultTitle,
                                                  usingHeadings: true)
        _ = note.setTitle(title)
        _ = note.setBody(body)
            
        let added = addPastedNote(note)
        if added != nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .info,
                              message: "Imported 1 note from \(importURL.path)")
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Imported 1 note from \(importURL.path)"
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }

        editVC!.io = noteIO
        finishBatchOperation()
    }
    
    @IBAction func importOPMLusingListItems(_ sender: Any) {
        
        // See if we're ready to take action
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        guard let importURL = promptUserForImportFile(
                title: "Open an input OPML file",
                parent: noteIO.collection!.lib.getURL(type: .parent))
            else { return }
        
        let note = Note(collection: collection)

        let fileName = importURL.deletingPathExtension().lastPathComponent
 
        let defaultTitle = StringUtils.wordDemarcation(fileName,
                                            caseMods: ["u", "u", "l"],
                                            delimiter: " ")
        
        let opmlToBody = OPMLtoBody()
        let (body, title) = opmlToBody.importFrom(importURL,
                                                  defaultTitle: defaultTitle,
                                                  usingHeadings: false)
        _ = note.setTitle(title)
        _ = note.setBody(body)
            
        let added = addPastedNote(note)
        if added != nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionWindowController",
                              level: .info,
                              message: "Imported 1 note from \(importURL.path)")
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Imported 1 note from \(importURL.path)"
            alert.addButton(withTitle: "OK")
            _ = alert.runModal()
        }

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
    
    @IBAction func populateAppCatalog(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        
        let openPanel = NSOpenPanel();
        openPanel.title = "Select Applications Folder"
        openPanel.directoryURL = noteIO.collection!.lib.getURL(type: .parent)
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select Applications folder"
        let userChoice = openPanel.runModal()
        guard userChoice == .OK else { return }
        guard let importURL = openPanel.url else { return }
        
        let alert = NSAlert()
        alert.messageText = "Please Confirm Choices"
        var info = "Notenik will scan for applications within:\n"
        info.append("\(importURL.path)\n")
        info.append("And add app info to the Collection at:\n")
        info.append("\(noteIO.collection!.fullPath)")
        alert.informativeText = info
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        
        let appPop = AppPop()
        appPop.populate(noteIO: noteIO, appFolder: importURL)
        
        reloadCollection(self)
        finishBatchOperation()
    }
    
    @IBAction func datesToCalendar(_ sender: Any) {

        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        guard collection.sortParm == .tasksByDate || collection.sortParm == .datePlusSeq else {
            communicateError("Collection must be sorted by Date in order to generate a calendar", alert: true)
            return
        }
        
        let (lowIndex, highIndex) = listVC!.getRangeOfSelectedRows()
        guard lowIndex >= 0 else {
            communicateError("Select one or more Notes in the months you wish included")
            return
        }
        
        guard let lowNote = noteIO.getNote(at: lowIndex) else { return }
        guard let highNote = noteIO.getNote(at: highIndex) else { return }
        
        let lowDateValue = lowNote.date
        let highDateValue = highNote.date
        
        var lowYM = lowDateValue.yearAndMonth
        var highYM = highDateValue.yearAndMonth
        
        if lowYM > highYM {
            let temp = lowYM
            lowYM = highYM
            highYM = temp
        }
        
        reportRunner = ReportRunner(io: noteIO)
        reportRunner!.runCalendar(lowYM: lowYM, highYM: highYM)
        
    }
    
    @IBAction func favoritesToHTML(_ sender: Any) {
        // See if we're ready to take action
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        reportRunner = ReportRunner(io: noteIO)
        reportRunner!.runFavorites()
    }
    
    /// Generate a Web Book of CSS and HTML pages, containing the entire Collection.
    @IBAction func generateWebBook(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        let dialog = NSOpenPanel()
        
        if !collection.webBookPath.isEmpty {
            let webBookURL = URL(fileURLWithPath: collection.webBookPath)
            let parent = webBookURL.deletingLastPathComponent()
            dialog.directoryURL = parent
        }
        
        dialog.title                   = "Choose an Output Folder for your Web Book"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = true
        
        let response = dialog.runModal()
         
        if response == .OK {
            let bookURL = dialog.url!
            let maker = WebBookMaker(input: noteIO.collection!.fullPathURL!, output: bookURL, webBookType: .website)
            if maker != nil {
                collection.webBookPath = bookURL.path
                collection.webBookAsEPUB = true
                let filesWritten = maker!.generate()
                informUserOfImportExportResults(operation: "Generate Web Book", ok: true, numberOfNotes: filesWritten, path: bookURL.path)
            }
        }
        
    }
    
    @IBAction func publishWebBookAsSite(_ sender: Any) {
        
        guard let noteIO = guardForCollectionAction() else { return }
        guard let collection = noteIO.collection else { return }
        
        let dialog = NSOpenPanel()
        
        if !collection.webBookPath.isEmpty {
            let webBookURL = URL(fileURLWithPath: collection.webBookPath)
            let parent = webBookURL.deletingLastPathComponent()
            dialog.directoryURL = parent
        }
        
        dialog.title                   = "Choose an Output Folder for your Web Book"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = true
        
        let response = dialog.runModal()
         
        if response == .OK {
            let bookURL = dialog.url!
            let maker = WebBookMaker(input: noteIO.collection!.fullPathURL!, output: bookURL, webBookType: .website)
            if maker != nil {
                collection.webBookPath = bookURL.path
                collection.webBookAsEPUB = false
                let filesWritten = maker!.generate()
                informUserOfImportExportResults(operation: "Generate Web Book", ok: true, numberOfNotes: filesWritten, path: bookURL.path)
            }
        }
    }
    
    /// Ask the user where to save the export file
    func getExportURL(fileExt: String, fileName: String = "export") -> URL? {
        guard io != nil && io!.collectionOpen else { return nil }
        
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return nil }
        applyCheckBoxUpdates()
        
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
            MultiFileIO.shared.registerBookmark(url: savePanel.url!)
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
    
    /// Export the Collection to a CSV file and request that it be opned by the user's
    /// default app for this kind of file.
    @IBAction func quickExportAndOpen(_ sender: Any) {
        
        // See if everything is copacetic.
        let nio = guardForCollectionAction()
        guard let noteIO = nio else { return }
        
        // Make sure we have a folder in which to place the export file.
        guard let collectionURL = noteIO.collection!.fullPathURL else { return }
        guard let exportFolder = FileUtils.ensureFolder(parentURL: collectionURL, folder: "quick-export") else {
            return
        }
        
        // Assign a standard file name.
        let destination = exportFolder.appendingPathComponent("export").appendingPathExtension("csv")
        
        // Now let's export.
        let exporter = NotesExporter()
        let notesExported = exporter.export(noteIO: noteIO,
                                            format: .commaSeparated,
                                            useTagsExportPrefs: false,
                                            split: false,
                                            addWebExtensions: false,
                                            destination: destination,
                                            ext: "csv")
        var ok = notesExported > 0
        informUserOfImportExportResults(operation: "export",
                                        ok: ok,
                                        numberOfNotes: notesExported,
                                        path: destination.path)
        
        guard ok else { return }
        
        // Now let's have an app open it.
        ok = NSWorkspace.shared.open(destination)
        if !ok {
            communicateError("File at \(destination) could not be opened by a default app", alert: true)
        }
    }
    
    func exportToICal(startingRow: Int, endingRow: Int) {
        guard let noteIO = guardForCollectionAction() else { return }
        let driver = NotesToTextDriver(io: noteIO, format: .iCal)
        let notesExported = driver.toText(startingRow: startingRow, endingRow: endingRow)
        var written = false
        if notesExported > 0 {
            written = driver.quickExport()
        }
        
        var ok = notesExported > 0 && written
        informUserOfImportExportResults(operation: "export to iCal",
                                        ok: ok,
                                        numberOfNotes: notesExported,
                                        path: driver.getDestination()!.absoluteString)
        
        guard ok else { return }
        
        // Now let's have an app open it.
        ok = NSWorkspace.shared.open(driver.destination!)
        if !ok {
            communicateError("File at \(driver.getDestination()!) could not be opened by a default app", alert: true)
        }
 
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
    
    @IBAction func stashNotenikFilesInSubfolder(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        noteIO.stashNotenikFilesInSubfolder()
    }
    
    @IBAction func genMirrorSample(_ sender: Any) {
        guard let noteIO = guardForCollectionAction() else { return }
        let collection = noteIO.collection!
        guard collection.mirror == nil else {
            communicateError("This Collection already has a functioning mirror folder",
                             alert: true)
            return
        }
        var mirrorMsg = ""
        (collection.mirror, mirrorMsg) = NoteTransformer.genSampleMirrorFolder(io: noteIO)
        if collection.mirror == nil {
            communicateError(mirrorMsg,
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
    
    /// Run a selected report.
    /// - Parameter sender: The menu item for the report selected by the user.
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
                reportRunner = ReportRunner(io: noteIO)
                let runOK = reportRunner!.runReport(noteIO.reports[i])
                if !runOK {
                    communicateError("Could not run selected report", alert: true)
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
        let qol = QueryOutputLauncher(windowTitle: "Query Output")
        var ok = template.openTemplate(templateURL: templateURL)
        if ok {
            template.supplyData(notesList: io.notesList,
                                dataSource: collection.fullPath)
            ok = template.generateOutput(templateOutputConsumer: qol)
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
                               info: "Edit \(NotenikConstants.displayHTMLFileName)"
                               + " and \(NotenikConstants.displayCSSFileName)"
                               + " files as needed",
                               alert: true)
        } else {
            communicateError("Sample Display Template and CSS files could not be created")
        }
    }
    
    /// Expand the given tag so that its children are visible
    /// - Parameter forTag: The tag to be expanded.
    public func expand(forTag: String) {
        guard let ctabs = collectionTabs else { return }
        guard let tvc = tagsVC else { return }
        ctabs.selectedTabViewItemIndex = 1
        tvc.expand(forTag: forTag)
    }
    
    // ----------------------------------------------------------------------------------
    //
    // The following section of code implements the NSFilePresenter protocol.
    //
    // ----------------------------------------------------------------------------------
    
    var presentedItemURL: URL?
    
    lazy var presentedItemOperationQueue: OperationQueue = OperationQueue.main
    
    func startFileCoordination() {
        // presentedItemURL = notenikIO!.collection!.fullPathURL
        // NSFileCoordinator.addFilePresenter(self)
        // print("CollectionWindowController.startFileCoordination for \(presentedItemURL!)")
    }
    
    func finishFileCoordination() {
        /* if presentedItemURL != nil {
            print("CollectionWindowController.finishFileCoordination for \(presentedItemURL!)")
            NSFileCoordinator.removeFilePresenter(self)
            presentedItemURL = nil
        } */
    }
    
    func presentedSubitemDidChange(at: URL) {
        // print("NSFilePresenter presented sub item did change at: \(at)")
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
                
        applyCheckBoxUpdates()
        
        guard !pendingMod else { return (nil, nil) }
        guard io != nil && io!.collectionOpen else { return (nil, nil) }
        var note: Note?
        (note, _) = io!.getSelectedNote()
        if note == nil {
            let (first, _) = listVC!.getRangeOfSelectedRows()
            if first >= 0 && first < io!.notesCount {
                _ = io!.selectNote(at: first)
                (note, _) = io!.getSelectedNote()
            }
        }
        guard note != nil else { return (io!, nil) }
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return (io!, nil) }
        return (io!, note!)
    }
    

    /// See if we're ready to do something affecting multiple Notes in the Collection.
    ///
    /// - Returns: The Notenik I/O module to use, if we're ready to go, otherwise nil.
    func guardForCollectionAction() -> NotenikIO? {
        
        applyCheckBoxUpdates()
        
        guard !pendingMod else { return nil }
        guard io != nil && io!.collectionOpen else { return nil }
        let (outcome, _) = modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else { return nil }
        return io
    }
    
    /// If any check box updates are pending, apply them now.
    func applyCheckBoxUpdates() {
        guard !pendingMod else { return }
        guard io != nil && io!.collectionOpen else { return }
        let (selNote, _) = io!.getSelectedNote()
        guard selNote != nil else { return }
        if selNote!.hasCheckBoxUpdates {
            let modNote = selNote!.copy() as! Note
            let modified = modNote.applyCheckBoxUpdates()
            if modified {
                let (chgNote, _) = io!.modNote(oldNote: selNote!, newNote: modNote)
                if chgNote != nil {
                    selNote!.clearCheckBoxUpdates()
                    chgNote!.clearCheckBoxUpdates()
                    displayModifiedNote(updatedNote: chgNote!)
                    editVC!.select(note: chgNote!)
                }
            }
        }
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
        // reloadViews()
        let (note, position) = io!.firstNote()
        _ = viewCoordinator.focusOn(initViewID: collectionViewID,
                                    note: note,
                                    position: position,
                                    row: -1, searchPhrase: nil,
                                    withUpdates: true)
        // select(note: note, position: position, source: .action, andScroll: true)
    }
    
}

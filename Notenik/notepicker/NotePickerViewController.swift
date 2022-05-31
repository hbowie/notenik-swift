//
//  NotePickerViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 3/11/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class NotePickerViewController: NSViewController,
                                    NSComboBoxDataSource,
                                    NSTableViewDataSource,
                                    NSTableViewDelegate,
                                    NSTextFieldDelegate {
    
    let multi = MultiFileIO.shared
    
    var folders: [QuickActionFolder] = []
    let initalFolderShortcut: String = ""
    var initalFolder = QuickActionFolder()
    
    let downArrow                 : UInt16 = 0x7D
    let upArrow                   : UInt16 = 0x7E
    
    let copyTitle       = "Copy Title"
    let copyPasteTitle  = "Copy and Paste Title"
    let copyLink        = "Copy Wikilink"
    let copyPasteLink   = "Copy and Paste Wikilink"
    let copyPasteInc    = "Copy and Paste Include Command"
    let copyTimestamp   = "Copy Timestamp"
    let copyPasteStamp  = "Copy and Paste Timestamp"
    let copyNotenikURL  = "Copy Notenik URL"
    let copyPasteURL    = "Copy and Paste Notenik URL"
    let goToAction      = "Go To"
    let launchAction    = "Launch Link"
    
    var collectionController: CollectionWindowController?
    var wc: NotePickerWindowController?

    @IBOutlet var shortcutComboBox: NSComboBox!
    @IBOutlet var titleTextField:   NSTextField!
    @IBOutlet var noteTableView:    NSTableView!
    @IBOutlet var actionList:       NSPopUpButton!
    
    var shortcutToUse = ""
    var ioToUse: NotenikIO?
    
    var targetingAnotherCollection: Bool {
        if ioToUse?.collection?.fullPath == noteIO?.collection?.fullPath {
            return false
        } else {
            return true
        }
    }
    
    var matchingTitles: [String] = []
    var lastTitleTextLength = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        noteTableView.delegate = self
        noteTableView.dataSource = self
        
        actionList.removeAllItems()
        actionList.addItem(withTitle: copyTitle)
        actionList.addItem(withTitle: copyPasteTitle)
        actionList.addItem(withTitle: copyLink)
        actionList.addItem(withTitle: copyPasteLink)
        actionList.addItem(withTitle: copyPasteInc)
        actionList.addItem(withTitle: copyTimestamp)
        actionList.addItem(withTitle: copyPasteStamp)
        actionList.addItem(withTitle: copyNotenikURL)
        actionList.addItem(withTitle: copyPasteURL)
        actionList.addItem(withTitle: goToAction)
        actionList.addItem(withTitle: launchAction)
        
        let lastAction = AppPrefs.shared.noteAction
        if !lastAction.isEmpty {
            actionList.selectItem(withTitle: lastAction)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.myKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
        
        shortcutComboBox.stringValue = initalFolderShortcut
        loadFolders()
        shortcutComboBox.usesDataSource = true
        shortcutComboBox.dataSource = self
        
        titleTextField.becomeFirstResponder()
    }
    
    var noteIO: NotenikIO? {
        get {
            return _noteIO
        }
        set {
            _noteIO = newValue
            tailorForCollection()
        }
    }
    var _noteIO: NotenikIO?
    
    func tailorForCollection() {
        guard let url = noteIO?.collection?.fullPathURL else { return }
        initalFolder.link = NotenikLink(url: url, isCollection: true)
        setTargetCollection(targetShortcut: initalFolderShortcut, targetIO: noteIO!)
    }
    
    /// Load the available folders along with their shortcuts.
    func loadFolders() {
        folders = []
        for folder in NotenikFolderList.shared {
            if !folder.shortcut.isEmpty {
                let item = QuickActionFolder(shortcut: folder.shortcut, link: folder)
                folders.append(item)
            }
        }
        folders.sort()
    }
    
    @IBAction func shortcutComboBoxAction(_ sender: NSComboBox) {
        guard let io = noteIO else { return }
        let str = sender.stringValue
        let i = indexForFolderShortcut(str)
        guard i != NSNotFound else { return }
        if i == 0 {
            setTargetCollection(targetShortcut: initalFolderShortcut, targetIO: io)
        } else {
            let multiIO = multi.getFileIO(shortcut: str)
            if multiIO != nil {
                setTargetCollection(targetShortcut: str, targetIO: multiIO!)
            }
        }
    }
    
    /// Set the Collection to be used for Note lookups.
    func setTargetCollection(targetShortcut: String, targetIO: NotenikIO) {
        if targetShortcut == shortcutToUse && targetIO.collection?.fullPath == ioToUse?.collection?.fullPath {
            // Nothing appears to have changed, so no need to proceed.
            return
        }
        shortcutToUse = targetShortcut
        ioToUse = targetIO
        titleTextField.stringValue = ""
        matchingTitles = []
        lastTitleTextLength = 0
        titleTextField.becomeFirstResponder()
    }
    
    /// Return the index of the folder with the passed shortcut.
    /// - Parameter str: The shortcut.
    /// - Returns: The index of the matching entry, or NSNotFound if nothing matches.
    func indexForFolderShortcut(_ str: String) -> Int {
        let lower = str.lowercased()
        if lower == "" || lower == " " || lower == "  " || lower == initalFolderShortcut {
            return 0
        }
        var i = 0
        while i < folders.count {
            if folders[i].shortcut == lower {
                return i + 1
            }
            i += 1
        }
        return NSNotFound
    }
    
    /// Update list of matching note titles to correspond to entered text.
    func controlTextDidChange(_ obj: Notification) {
        
        let textToMatch = titleTextField.stringValue.lowercased()
        
        if textToMatch.count < 3 {
            // Fewer than three characters entered - empty out the table of possible matches
            matchingTitles = []
        } else if ioToUse == nil {
            // No I/O module? Then nothing to show.
            matchingTitles = []
        } else if textToMatch.count > lastTitleTextLength && lastTitleTextLength >= 3{
            // User is entering more characters -- narrow the selections in the list.
            var i = 0
            while i < matchingTitles.count {
                if matchingTitles[i].lowercased().contains(textToMatch) {
                    i += 1
                } else {
                    matchingTitles.remove(at: i)
                }
            }
        } else {
            // Reload the table with titles that match the entered characters.
            matchingTitles = []
            
            var i = 0
            while i < ioToUse!.count {
                let note = ioToUse!.getNote(at: i)
                if note!.title.value.lowercased().contains(textToMatch) {
                    matchingTitles.append(note!.title.value)
                }
                i += 1
            }
            
            let akaAll = ioToUse!.getAKAEntries()
            for (aka, note) in akaAll.akaDict {
                if aka.lowercased().contains(textToMatch) {
                    for originalAKA in note.aka.list {
                        if aka == StringUtils.toCommon(originalAKA) {
                            matchingTitles.append(originalAKA)
                        }
                    }
                }
            }
            
            matchingTitles.sort()
        }
        
        lastTitleTextLength = textToMatch.count
        noteTableView.reloadData()
        if matchingTitles.count > 0 {
            noteTableView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    @IBAction func titleTextAction(_ sender: Any) {

    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard ioToUse != nil else { return 0 }
        return matchingTitles.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard row >= 0 && row < matchingTitles.count else { return nil }
        let cellID = NSUserInterfaceItemIdentifier(rawValue: "TitleCellID")
        guard let anyView = noteTableView.makeView(withIdentifier: cellID, owner: self) else { return nil }
        guard let cellView = anyView as? NSTableCellView else { return nil }
        cellView.textField?.stringValue = matchingTitles[row]
        
        return cellView
    }
    
    func myKeyDown(with event: NSEvent) -> Bool {
        guard let locWindow = self.view.window,
              NSApplication.shared.keyWindow === locWindow else { return false }
        
        var chars = " "
        if event.charactersIgnoringModifiers != nil {
            chars = event.charactersIgnoringModifiers!
        }
        if event.modifierFlags.contains(.command) {
            let row = noteTableView.selectedRow
            guard row >= 0 && row < matchingTitles.count else { return false }
            let title = matchingTitles[row]
            switch chars {
            case "c":
                if event.modifierFlags.contains(.option) {
                    AppPrefs.shared.noteAction = copyLink
                    copyNoteTitleWithBrackets(title: title)
                    return true
                } else {
                    AppPrefs.shared.noteAction = copyTitle
                    copyNoteTitle(title: title)
                    return true
                }
            case "g":
                AppPrefs.shared.noteAction = goToAction
                goTo(title: title)
                return true
            case "l":
                AppPrefs.shared.noteAction = launchAction
                launchLink(title: title)
                return true
            case "t":
                AppPrefs.shared.noteAction = copyTimestamp
                copyNoteTimestamp(title: title)
                return true
            case "v":
                if event.modifierFlags.contains(.option) {
                    AppPrefs.shared.noteAction = copyPasteLink
                    copyPasteNoteTitleWithBrackets(title: title)
                    return true
                } else {
                    AppPrefs.shared.noteAction = copyPasteTitle
                    copyPasteNoteTitle(title: title)
                    return true
                }
            default:
                break
            }
        }
        switch event.keyCode {
        case downArrow:
            var i = noteTableView.selectedRow
            i += 1
            if i < noteTableView.numberOfRows {
                noteTableView.selectRowIndexes([i], byExtendingSelection: false)
            }
            return true
        case upArrow:
            var i = noteTableView.selectedRow
            i -= 1
            if i >= 0 && i < noteTableView.numberOfRows {
                noteTableView.selectRowIndexes([i], byExtendingSelection: false)
            }
            return true
        default:
            return false
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func ok(_ sender: Any) {
  
        guard let selectedAction = actionList.selectedItem else { return }
        AppPrefs.shared.noteAction = selectedAction.title
        let row = noteTableView.selectedRow
        guard row >= 0 && row < matchingTitles.count else { return }
        let title = matchingTitles[row]
        
        // Perform the requested action.
        switch selectedAction.title {
        case copyTitle:
            copyNoteTitle(title: title)
        case copyPasteTitle:
            copyPasteNoteTitle(title: title)
        case copyLink:
            if targetingAnotherCollection {
                copyNotenikURLasMDlink(title: title)
            } else {
                copyNoteTitleWithBrackets(title: title)
            }
        case copyPasteLink:
            if targetingAnotherCollection {
                copyPasteNotenikURLasMDlink(title: title)
            } else {
                copyPasteNoteTitleWithBrackets(title: title)
            }
        case copyPasteInc:
            copyPasteInclude(title: title)
        case copyTimestamp:
            copyNoteTimestamp(title: title)
        case copyPasteStamp:
            copyPasteNoteTimestamp(title: title)
        case copyNotenikURL:
            copyNotenikURLForNote(title: title)
        case copyPasteURL:
            copyPasteNotenikURLForNote(title: title)
        case goToAction:
            if targetingAnotherCollection {
                goToAnotherCollection(title: title)
            } else {
                goTo(title: title)
            }
        case launchAction:
            launchLink(title: title)
        default:
            break
        }
    }
    
    /// Copy the title of the indicated Note to the System pasteboard.
    func copyNoteTitle(title: String) {
        strToPasteboard(title)
    }
    
    func copyPasteNoteTitle(title: String) {
        strToPasteboard(title, paste: true)
    }
    
    func copyNoteTitleWithBrackets(title: String) {
        strToPasteboard("[[\(title)]]")
    }
    
    func copyPasteNoteTitleWithBrackets(title: String) {
        strToPasteboard("[[\(title)]]", paste: true)
    }
    
    func copyPasteInclude(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        if note.hasKlass() && note.klass.quote {
            strToPasteboard("{:include-quote:\(title)}", paste: true)
        } else {
            strToPasteboard("{:include:\(title)}", paste: true)
        }
    }
    
    func copyNoteTimestamp(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard(note.timestampAsString)
    }
    
    func copyPasteNoteTimestamp(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard(note.timestampAsString, paste: true)
    }
    
    func copyNotenikURLForNote(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard(note.getNotenikLink())
    }
    
    func copyPasteNotenikURLForNote(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard(note.getNotenikLink(), paste: true)
    }
    
    func copyNotenikURLasMDlink(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard("[\(title)](\(note.getNotenikLink()))")
    }
    
    func copyPasteNotenikURLasMDlink(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        strToPasteboard("[\(title)](\(note.getNotenikLink()))", paste: true)
    }
    
    func goTo(title: String) {
        guard let io = noteIO else { return }
        guard let collWC = collectionController else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        collWC.select(note: note, position: nil, source: .nav)
        closeWindow()

    }
    
    func goToAnotherCollection(title: String) {
        guard let io = ioToUse else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        let actor = CustomURLActor()
        _ = actor.act(on: note.getNotenikLink())
        closeWindow()
    }
    
    func launchLink(title: String) {
        guard let io = ioToUse else { return }
        guard let collWC = collectionController else { return }
        guard let note = io.getNote(knownAs: title) else { return }
        collWC.launchLink(for: note)
        closeWindow()
    }
    
    func strToPasteboard(_ str: String, paste: Bool = false, closing: Bool = true) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(str, forType: .string)
        if closing {
            closeWindow()
        }
        if paste {
            if let collWC = collectionController {
                collWC.pasteTextNow()
            }
        }
    }
    
    func closeWindow() {
        guard wc != nil else { return }
        wc!.close()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: NSComboBoxDataSource methods for shortcut combo box.
    //
    // -----------------------------------------------------------
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        guard comboBox == shortcutComboBox else { return nil }
        let lower = string.lowercased()
        if lower == "" || lower == " " || lower == "  " || lower == initalFolderShortcut {
            return initalFolderShortcut
        }
        var i = 0
        while i < folders.count {
            if folders[i].shortcut.hasPrefix(lower) {
                return folders[i].shortcut
            }
            i += 1
        }
        return nil
    }
    
    /// Returns the index of the combo box matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        guard comboBox == shortcutComboBox else { return NSNotFound }
        let i = indexForFolderShortcut(string)
        return i
    }
    
    /// Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard comboBox == shortcutComboBox else { return nil }
        if index < 1 {
            return initalFolder
        } else {
            return folders[index - 1]
        }
    }
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        guard comboBox == shortcutComboBox else { return 0 }
        return folders.count + 1
    }
    
}

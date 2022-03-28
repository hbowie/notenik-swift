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
                                    NSTableViewDataSource,
                                    NSTableViewDelegate,
                                    NSTextFieldDelegate {
    
    let downArrow                 : UInt16 = 0x7D
    let upArrow                   : UInt16 = 0x7E
    
    let copyTitle      = "Copy Title"
    let copyPasteTitle = "Copy and Paste Title"
    let copyLink       = "Copy Wikilink"
    let copyPasteLink  = "Copy and Paste Wikilink"
    let copyTimestamp  = "Copy Timestamp"
    let copyPasteStamp = "Copy and Paste Timestamp"
    let goToAction     = "Go To"
    let launchAction   = "Launch Link"
    
    var collectionController: CollectionWindowController?
    var wc: NotePickerWindowController?

    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var noteTableView: NSTableView!
    @IBOutlet var actionList: NSPopUpButton!
    
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
        actionList.addItem(withTitle: copyTimestamp)
        actionList.addItem(withTitle: copyPasteStamp)
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
    }
    
    var noteIO: NotenikIO? {
        get {
            return _noteIO
        }
        set {
            _noteIO = newValue
            // tailorForCollection()
        }
    }
    var _noteIO: NotenikIO?
    
    /// Update list of matching note titles to correspond to entered text.
    func controlTextDidChange(_ obj: Notification) {
        
        let textToMatch = titleTextField.stringValue.lowercased()
        
        if textToMatch.count < 3 {
            // Fewer than three characters entered - empty out the table of possible matches
            matchingTitles = []
        } else if noteIO == nil {
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
            while i < noteIO!.count {
                let note = noteIO!.getNote(at: i)
                if note!.title.value.lowercased().contains(textToMatch) {
                    matchingTitles.append(note!.title.value)
                }
                i += 1
            }
            
            let akaAll = noteIO!.getAKAEntries()
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
        guard noteIO != nil else { return 0 }
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
            switch chars {
            case "c":
                if event.modifierFlags.contains(.option) {
                    AppPrefs.shared.noteAction = copyLink
                    copyNoteTitleWithBrackets()
                    return true
                } else {
                    AppPrefs.shared.noteAction = copyTitle
                    copyNoteTitle()
                    return true
                }
            case "g":
                AppPrefs.shared.noteAction = goToAction
                goTo()
                return true
            case "l":
                AppPrefs.shared.noteAction = launchAction
                launchLink()
                return true
            case "t":
                AppPrefs.shared.noteAction = copyTimestamp
                copyNoteTimestamp()
                return true
            case "v":
                if event.modifierFlags.contains(.option) {
                    AppPrefs.shared.noteAction = copyPasteLink
                    copyPasteNoteTitleWithBrackets()
                    return true
                } else {
                    AppPrefs.shared.noteAction = copyPasteTitle
                    copyPasteNoteTitle()
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
  
        if let selectedAction = actionList.selectedItem {
            AppPrefs.shared.noteAction = selectedAction.title
            
            // Perform the requested action.
            switch selectedAction.title {
            case copyTitle:
                copyNoteTitle()
            case copyPasteTitle:
                copyPasteNoteTitle()
            case copyLink:
                copyNoteTitleWithBrackets()
            case copyPasteLink:
                copyPasteNoteTitleWithBrackets()
            case copyTimestamp:
                copyNoteTimestamp()
            case copyPasteStamp:
                copyPasteNoteTimestamp()
            case goToAction:
                goTo()
            case launchAction:
                launchLink()
            default:
                break
            }
        }
    }
    
    func copyNoteTitle() {
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(selectedTitle, forType: .string)
        closeWindow()
    }
    
    func copyNoteTitleWithBrackets() {
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("[[\(selectedTitle)]]", forType: .string)
        closeWindow()
    }
    
    func copyPasteNoteTitle() {
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(selectedTitle, forType: .string)
        closeWindow()
        collWC.pasteTextNow()
    }
    
    func copyPasteNoteTitleWithBrackets() {
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString("[[\(selectedTitle)]]", forType: .string)
        closeWindow()
        collWC.pasteTextNow()
    }
    
    func copyNoteTimestamp() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard let io = noteIO else { return }
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        guard let note = io.getNote(knownAs: selectedTitle) else { return }
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(note.timestampAsString, forType: .string)
        closeWindow()
    }
    
    func copyPasteNoteTimestamp() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard let io = noteIO else { return }
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        guard selectedRow >= 0 && selectedRow < matchingTitles.count else { return }
        let selectedTitle = matchingTitles[selectedRow]
        guard let note = io.getNote(knownAs: selectedTitle) else { return }
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(note.timestampAsString, forType: .string)
        closeWindow()
        collWC.pasteTextNow()
    }
    
    func goTo() {
        guard let io = noteIO else { return }
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        if selectedRow >= 0 && selectedRow < matchingTitles.count {
            let selectedTitle = matchingTitles[selectedRow]
            let note = io.getNote(knownAs: selectedTitle)
            if note != nil {
                collWC.select(note: note!, position: nil, source: .nav)
                closeWindow()
            }
        }
    }
    
    func launchLink() {
        guard let io = noteIO else { return }
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        if selectedRow >= 0 && selectedRow < matchingTitles.count {
            let selectedTitle = matchingTitles[selectedRow]
            let note = io.getNote(knownAs: selectedTitle)
            if note != nil {
                collWC.launchLink(for: note!)
                closeWindow()
            }
        }
    }
    
    func closeWindow() {
        guard wc != nil else { return }
        wc!.close()
    }
    
    
}

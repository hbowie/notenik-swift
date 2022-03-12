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

class NotePickerViewController: NSViewController,
                                    NSTableViewDataSource,
                                    NSTableViewDelegate,
                                    NSTextFieldDelegate {
    
    let copyTitle      = "Copy Title"
    let copyPasteTitle = "Copy and Paste Title"
    let copyLink       = "Copy Wikilink"
    let copyPasteLink  = "Copy and Paste Wikilink"
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
        actionList.addItem(withTitle: goToAction)
        actionList.addItem(withTitle: launchAction)
        
        let lastAction = AppPrefs.shared.noteAction
        if !lastAction.isEmpty {
            actionList.selectItem(withTitle: lastAction)
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
            for (aka, _) in akaAll.akaDict {
                if aka.lowercased().contains(textToMatch) {
                    matchingTitles.append(aka)
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
    
    @IBAction func cancel(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func ok(_ sender: Any) {
        guard let io = noteIO else { return }
        guard let collWC = collectionController else { return }
        let selectedRow = noteTableView.selectedRow
        if selectedRow >= 0 && selectedRow < matchingTitles.count {
            let selectedTitle = matchingTitles[selectedRow]
            if let selectedAction = actionList.selectedItem {
                AppPrefs.shared.noteAction = selectedAction.title
                
                // Perform the requested action.
                switch selectedAction.title {
                case copyTitle:
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(selectedTitle, forType: .string)
                case copyPasteTitle:
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(selectedTitle, forType: .string)
                    collWC.pasteTextNow()
                case copyLink:
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString("[[\(selectedTitle)]]", forType: .string)
                case copyPasteLink:
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString("[[\(selectedTitle)]]", forType: .string)
                    collWC.pasteTextNow()
                case goToAction:
                    let note = io.getNote(knownAs: selectedTitle)
                    if note != nil {
                        collWC.select(note: note!, position: nil, source: .nav)
                    }
                case launchAction:
                    let note = io.getNote(knownAs: selectedTitle)
                    if note != nil {
                        collWC.launchLink(for: note!)
                    }
                default:
                    break
                }
            }
        }

        closeWindow()
    }
    
    func closeWindow() {
        guard wc != nil else { return }
        wc!.close()
    }
    
    
}

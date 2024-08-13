//
//  QuickActionViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/11/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class QuickActionViewController: NSViewController, NSComboBoxDataSource {
    
    let prefs = AppPrefs.shared
    
    var juggler: CollectionJuggler?
    var window:  QuickActionWindowController!
    
    var folders: [QuickActionFolder] = []
    var noteTitles: [String] = []

    @IBOutlet var shortcutComboBox: NSComboBox!
    var collectionWC: CollectionWindowController?
    
    var lastPosition = NotePosition(index: -1)
    
    var todayFormatter = DateFormatter()
    
    @IBOutlet var noteTitleComboBox: NSComboBox!
    
    @IBOutlet var bodyTextView: NSTextView!
    
    /// Build out the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        todayFormatter.dateFormat = "yyyy-MM-dd EEEE"
        shortcutComboBox.stringValue = prefs.lastShortcut
        loadFolders()
        shortcutComboBox.usesDataSource = true
        shortcutComboBox.dataSource = self
        noteTitleComboBox.usesDataSource = true
        noteTitleComboBox.dataSource = self
    }
    
    /// Reload the data to make sure it is up-to-date.
    func restart() {
        loadFolders()
        shortcutComboBox.reloadData()
        shortcutComboBox.stringValue = prefs.lastShortcut
        shortcutComboBox.becomeFirstResponder()
        collectionWC = nil
        loadNoteTitles()
        noteTitleComboBox.reloadData()
        noteTitleComboBox.stringValue = ""
        bodyTextView.string = ""
    }
    
    /// Load the available folders along with their shortcuts.
    func loadFolders() {
        folders = []
        for folder in NotenikFolderList.shared {
            if folder.shortcut.count > 0 {
                let item = QuickActionFolder(shortcut: folder.shortcut, link: folder)
                folders.append(item)
            }
        }
        folders.sort()
    }
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox == shortcutComboBox {
            return folders.count
        } else {
            return noteTitles.count
        }
    }
        
    /// Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox == shortcutComboBox {
            return folders[index]
        } else {
            return noteTitles[index]
        }
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        if comboBox == shortcutComboBox {
            let lower = string.lowercased()
            var i = 0
            while i < folders.count {
                if folders[i].shortcut.hasPrefix(lower) {
                    return folders[i].shortcut
                }
                i += 1
            }
            return nil
        } else {
            var i = 0
            while i < noteTitles.count {
                if noteTitles[i].hasPrefix(string) {
                    return noteTitles[i]
                }
                i += 1
            }
            return nil
        }
    }
    
    /// Returns the index of the combo box matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        if comboBox == shortcutComboBox {
            return indexForFolderShortcut(string)
        } else {
            return indexForNoteTitle(string)
        }
    }
    
    @IBAction func shortcutAction(_ sender: NSComboBox) {
        let str = sender.stringValue
        let i = indexForFolderShortcut(str)
        guard i != NSNotFound else { return }
        prefs.lastShortcut = str
        guard let link = folders[i].link else { return }
        collectionWC = open(link: link)
        loadNoteTitles()
        window.window?.makeKeyAndOrderFront(self)
    }
    
    /// Load the Note Titles for the selected Collection.
    func loadNoteTitles() {
        noteTitles = []
        guard let io = collectionWC?.io else { return }
        var (note, position) = io.firstNote()
        while note != nil {
            noteTitles.append(note!.title.value)
            noteTitles.append(note!.title.value.lowercased())
            (note, position) = io.nextNote(position)
        }
        noteTitles.sort()
    }
    
    @IBAction func noteTitleAction(_ sender: NSComboBox) {
        var str = sender.stringValue
        let strLower = str.lowercased()
        if strLower == "today" {
            let now = Date()
            let todayStr = todayFormatter.string(from: now)
            str = todayStr
            sender.stringValue = todayStr
        }
        let noteID = StringUtils.toCommon(noteTitleComboBox.stringValue)
        guard let wc = collectionWC else { return }
        guard let io = wc.io else { return }
        let matchingNote = io.getNote(forID: noteID)
        guard let note = matchingNote else { return }
        _ = wc.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                       note: note,
                                       position: nil, row: -1, searchPhrase: nil)
        // wc.select(note: note, position: nil, source: .action, andScroll: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func okToProceed(_ sender: Any) {
        let str = shortcutComboBox.stringValue
        prefs.lastShortcut = str
        let i = indexForFolderShortcut(str)
        guard i != NSNotFound else { return }
        guard let link = folders[i].link else { return }
        collectionWC = open(link: link)
        if collectionWC != nil {
            collectionWC!.updateNote(title: noteTitleComboBox.stringValue, bodyText: bodyTextView.string)
            closeWindow()
        }
    }
    
    /// Return the index of the folder with the passed shortcut.
    /// - Parameter str: The shortcut.
    /// - Returns: The index of the matching entry, or NSNotFound if nothing matches.
    func indexForFolderShortcut(_ str: String) -> Int {
        let lower = str.lowercased()
        var i = 0
        while i < folders.count {
            if folders[i].shortcut == lower {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
    /// Return the index of the Note title with the passed title.
    /// - Parameter str: The note title.
    /// - Returns: The index of the matching entry, or NSNotFound if nothing matches.
    func indexForNoteTitle(_ str: String) -> Int {
        var i = 0
        while i < noteTitles.count {
            if noteTitles[i] == str {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
    func open(link: NotenikLink) -> CollectionWindowController? {
        MultiFileIO.shared.secureAccess(shortcut: link.shortcut, url: link.url!)
        return juggler!.open(link: link)
    }
    
    /// Close the Quick Action Window.
    func closeWindow() {
        guard window != nil else { return }
        window!.close()
    }
    
}

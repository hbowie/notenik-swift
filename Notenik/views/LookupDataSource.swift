//
//  LookupDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 8/21/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class LookupDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    let multiFile = MultiFileIO.shared
    var io: FileIO?
    var notesList: NotesList?
    
    var fieldDef: FieldDefinition?
    
    override init() {
        super.init()
    }
    
    convenience init(def: FieldDefinition) {
        self.init()
        self.fieldDef = def
        loadNotesList()
    }
    
    func loadNotesList() {
        guard let def = fieldDef else { return }
        guard !def.lookupFrom.isEmpty else { return }
        io = multiFile.getFileIO(shortcut: fieldDef!.lookupFrom)
        notesList = multiFile.getNotesList(shortcut: fieldDef!.lookupFrom)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        guard notesList != nil else { return 0 }
        return notesList!.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard notesList != nil else { return nil }
        return notesList![index].title.value
    }
    
    /// Returns the first item from the pop-up list that starts with
    /// the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        guard notesList != nil else { return nil }
        var i = 0
        while i < notesList!.count {
            if notesList![i].title.value.hasPrefix(string) {
                return notesList![i].title.value
            } else if notesList![i].title.value > string && io!.collection!.sortParm == .title {
                return nil
            }
            i += 1
        }
        return nil
    }
    
    /// Returns the index of the combo box item
    /// matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        guard notesList != nil else { return NSNotFound }
        var i = 0
        while i < notesList!.count {
            if notesList![i].title.value == string {
                return i
            } else if notesList![i].title.value > string && io!.collection!.sortParm == .title {
                return NSNotFound
            }
            i += 1
        }
        return NSNotFound
    }
    
}

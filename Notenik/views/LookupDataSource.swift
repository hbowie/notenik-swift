//
//  LookupDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 8/21/21.
//
//  Copyright © 2021 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class LookupDataSource: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
    
    let multiFile = MultiFileIO.shared
    var lookupIO: FileIO?
    var comboValues: [String] = []
    
    var fieldDef: FieldDefinition?
    var lookupField: NSComboBox?
    
    override init() {
        super.init()
    }
    
    convenience init(def: FieldDefinition, field: NSComboBox) {
        self.init()
        self.fieldDef = def
        self.lookupField = field
        loadNotesList()
    }
    
    func loadNotesList() {
        guard let def = fieldDef else { return }
        guard !def.lookupFrom.isEmpty else { return }
        guard let io = multiFile.getFileIO(shortcut: fieldDef!.lookupFrom) else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "LookupDataSource",
                              level: .error,
                              message: "File I/O could not be opened for shortcut \(fieldDef!.lookupFrom)")
            return
        }
        lookupIO = io
        var note: Note?
        var pos: NotePosition?
        (note, pos) = io.firstNote()
        while (note != nil) {
            comboValues.append(note!.title.value.lowercased())
            (note, pos) = io.nextNote(pos!)
        }
        comboValues.sort()
    }
    
    /// Returns the number of items that the data source manages for the combo box.
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return comboValues.count
    }
    
    /// Returns the object that corresponds to the item at the specified index in the combo box.
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 && index < comboValues.count else { return nil }
        guard let io = lookupIO else { return nil }
        let comboValue = comboValues[index]
        guard let note = io.getNote(knownAs: comboValue) else { return nil }
        return note.title.value
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        
        let lookingFor = string.lowercased()
        for value in comboValues {
            if value.starts(with: lookingFor) {
                return value
            }
        }
        return nil
    }
    
    /// Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        
        let lookingFor = string.lowercased()
        var i = 0
        while i < comboValues.count {
            let value = comboValues[i]
            if lookingFor == value {
                return i
            }
            i += 1
        }
        return NSNotFound
    }
    
}

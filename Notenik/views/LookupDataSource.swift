//
//  LookupDataSource.swift
//  Notenik
//
//  Created by Herb Bowie on 8/21/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class LookupDataSource: ComboData {
    
    let multiFile = MultiFileIO.shared
    var lookupIO: FileIO?
    
    var fieldDef: FieldDefinition?
    
    override init() {
        super.init()
    }
    
    convenience init(def: FieldDefinition, field: NSComboBox) {
        self.init()
        self.fieldDef = def
        // self.lookupField = field
        loadNotesList()
    }
    
    func refreshData() {
        clearItems()
        loadNotesList()
    }
    
    func loadNotesList() {
        guard let def = fieldDef else { return }
        guard !def.lookupFrom.isEmpty else { return }
        let (collection, io) = multiFile.provision(shortcut: fieldDef!.lookupFrom, inspector: nil, readOnly: false)
        guard collection != nil else {
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
            addItem(note!.title.value)
            (note, pos) = io.nextNote(pos!)
        }
        sortItems()
    }
    
}

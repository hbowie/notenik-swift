//
//  ModIfChanged.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Bridge between a User Interface and an Input/Output Module
class ModWhenChanged {
    
    var io: NotenikIO
    
    init(io: NotenikIO) {
        self.io = io
    }
    
    /// Analyse the user's input and make appropriate changes to a Note through an
    /// I/O Module.
    ///
    /// - Parameters:
    ///   - newNoteRequested: Are we trying to add a new note, rather than modify an existing one?
    ///   - startingNote: The Note to which we want to compare the user's input.
    ///   - modViews: One user view for each field defined for the collection.
    /// - Returns: The outcome of the analysis and actions performed, plus the relevant Note.
    func modIfChanged(newNoteRequested: Bool,
                      startingNote: Note,
                      modViews: [ModView],
                      statusConfig: StatusValueConfig) -> (modIfChangedOutcome, Note?) {
        var outcome: modIfChangedOutcome = .notReady
        
        // See if we're ready for this
        guard let collection = io.collection else { return (outcome, nil) }
        guard io.collectionOpen else { return (outcome, nil) }
        
        let dict = collection.dict
        let defs = dict.list
        
        guard defs.count == modViews.count else {
            return (outcome, nil)
        }
        
        outcome = .noChange
        
        // Let's get a Note ready for comparison and possible modifications
        var modNote: Note
        if newNoteRequested {
            modNote = startingNote
        } else {
            modNote = startingNote.copy() as! Note
        }
        
        // See if any fields were modified by the user, and update corresponding Note fields
        var modified = false
        var i = 0
        for def in defs {
            let field = modNote.getField(def: def)
            let fieldView = modViews[i]
            var noteValue = ""
            if field != nil {
                noteValue = field!.value.value
            }
            var userValue = fieldView.text
            if def.fieldType is TagsType {
                let userTags = TagsValue(fieldView.text)
                userValue = userTags.value
            }
            if userValue != noteValue {
                let newValue = def.fieldType.createValue(userValue)
                if field == nil {
                    let newField = NoteField(def: def, statusConfig: statusConfig)
                    newField.value = newValue
                    let addOK = modNote.addField(newField)
                    if !addOK {
                        logError("Unable to add field to note")
                    }
                } else {
                    field!.value = newValue
                }
                modified = true
            }
            i += 1
        }
        
        // Were any fields modified?
        var existingNote: Note?
        if modified {
            outcome = .modify
            let modID = modNote.noteID
            
            // If we have a new Note ID, make sure it's unique
            var newID = newNoteRequested
            if newNoteRequested {
                outcome = .add
            }
            if !newNoteRequested {
                newID = (startingNote.noteID != modID)
                if newID {
                    outcome = .deleteAndAdd
                }
            }
            if newID {
                existingNote = io.getNote(forID: modID)
                if existingNote != nil {
                    outcome = .idAlreadyExists
                }
            }
            if outcome == .modify {
                if startingNote.sortKey != modNote.sortKey {
                    outcome = .deleteAndAdd
                } else if startingNote.tags != modNote.tags {
                    outcome = .deleteAndAdd
                }
            }
            if modID.count == 0 {
                outcome = .noChange
            }
        }
        
        
        // Figure out what we need to do
        switch outcome {
        case .notReady:
            return (outcome, nil)
        case .noChange:
            return (outcome, nil)
        case .idAlreadyExists:
            return (outcome, existingNote)
        case .tryAgain:
            return (outcome, nil)
        case .discard:
            return (outcome, nil)
        case .add:
            let (addedNote, _) = io.addNote(newNote: modNote)
            if addedNote != nil {
                return (outcome, addedNote)
            } else {
                logError("Problems adding note titled \(modNote.title)")
                return (.tryAgain, nil)
            }
        case .deleteAndAdd:
            modNote.fileInfo.optRegenFileName()
            let attachmentsOK = io.reattach(from: startingNote, to: modNote)
            if !attachmentsOK {
                logError("Problems renaming attachments for \(modNote.title)")
            }
            let (_, _) = io.deleteSelectedNote()
            let (addedNote, _) = io.addNote(newNote: modNote)
            if addedNote != nil {
                return (outcome, addedNote)
            } else {
                logError("Problems adding note titled \(modNote.title)")
                return (.tryAgain, nil)
            }
        case .modify:
            modNote.copyFields(to: startingNote)
            let writeOK = io.writeNote(startingNote)
            if !writeOK {
                logError("Write Note failed!")
            }
            return (outcome, startingNote)
        }
    } // end modIfChanged method
    
    /// Log an error message.
    func logError(_ msg: String) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ModWhenChanged",
                          level: .error,
                          message: msg)
        
    }
}

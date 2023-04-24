//
//  AddNoteFromTextIntentHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

@available(macOS 11.0, *)
class AddNoteFromTextIntentHandler: NSObject, AddNoteFromTextIntentHandling {
    
    func handle(intent: AddNoteFromTextIntent, completion: @escaping (AddNoteFromTextIntentResponse) -> Void) {
        guard let collWC = CollectionJuggler.shared.getLastUsedWindowController() else {
            let response = AddNoteFromTextIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }
        
        guard let collection = collWC.notenikIO?.collection else {
            let response = AddNoteFromTextIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }
        
        guard let noteText = intent.noteText else {
            let response = AddNoteFromTextIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }
        
        let newNote = Note(collection: collection)
        
        _ = collWC.strToNote(str: noteText, note: newNote, defaultTitle: nil)
        
        guard let addedNote = collWC.addPastedNote(newNote) else {
            let response = AddNoteFromTextIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }

        let url = URL(string: addedNote.getNotenikLink())
        let response = AddNoteFromTextIntentResponse(code: .success, userActivity: nil)
        response.noteSharingLink = url
        completion(response)
    }

}

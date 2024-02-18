//
//  AppAddNote.swift
//  Notenik
//
//  Created by Herb Bowie on 3/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

@objc class AppAddNote: NSScriptCommand {
    
    override init(commandDescription commandDef: NSScriptCommandDescription) {
        super.init(commandDescription: commandDef)
    }
    
    override func performDefaultImplementation() -> Any? {
        guard let args = self.evaluatedArguments else {
            return ""
        }
        let juggler = CollectionJuggler.shared
        guard let activeWC = juggler.getLastUsedWindowController() else { return "" }
        guard let io = activeWC.io else { return "" }
        guard let collection = io.collection else { return "" }
        guard let nsTitle = args["NoteTitle"] else { return "" }
        let title = String(describing: nsTitle)
        guard let nsLink = args["NoteLink"] else { return "" }
        let link = String(describing: nsLink)
        guard let nsTags = args["NoteTags"] else { return "" }
        let tags = String(describing: nsTags)
        let note = Note(collection: collection)
        _ = note.setTitle(title)
        _ = note.setLink(link)
        _ = note.setTags(tags)
        note.identify()
        guard let added = activeWC.addNewNote(note) else { return "" }
        return added.getNotenikLink(preferringTimestamp: true)
    }

}

//
//  CustomURLActor.swift
//  Notenik
//
//  Created by Herb Bowie on 5/21/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikLib
import NotenikUtils

/// Take some sort of action in response to a Notenik Custom URL.
class CustomURLActor {
    
    let folders = NotenikFolderList.shared
    let juggler = CollectionJuggler.shared
    
    init() {
        
    }
    
    func act(on customURL: String) -> Bool {
        logInfo(msg: "Received request to act on Custom URL: \(customURL)")
        guard let url = URL(string: customURL) else {
            communicateError("Could not fashion a URL from this string: \(customURL)")
            return false
        }
        guard let scheme = url.scheme else {
            communicateError("Could not extract a scheme from this URL: \(customURL)")
            return false
        }
        guard scheme == NotenikConstants.notenikURLScheme else {
            communicateError("Invalid scheme detected: \(scheme)")
            return false
        }
        guard let command = url.host else {
            communicateError("Could not extract a command from this URL: \(customURL)")
            return false
        }
        guard let query = url.query else {
            communicateError("Could not extract query parameters from this URL: \(customURL)")
            return false
        }
        var labels: [String] = []
        var values: [String] = []
        let parameters = query.components(separatedBy: "&")
        for parm in parameters {
            let parmSplit = parm.components(separatedBy: "=")
            guard parmSplit.count == 2 else { continue }
            labels.append(parmSplit[0])
            guard let value = parmSplit[1].removingPercentEncoding else { continue }
            values.append(value)
        }
        switch command {
        case "open":
            processOpenCommand(labels: labels, values: values)
        case "add":
            processAddCommand(labels: labels, values: values)
        default:
            communicateError("Invalid Command: \(command)")
            return false
        }
        return true
    }
    
    func processOpenCommand(labels: [String], values: [String]) {
        var cwc: CollectionWindowController?
        var i = 0
        while i < labels.count {
            processOpenParm(label: labels[i],
                            value: values[i],
                            cwc: &cwc)
            i += 1
        }
    }
    
    func processOpenParm(label: String,
                         value: String,
                         cwc:   inout CollectionWindowController?) {
        switch label {
        case "shortcut":
            cwc = openCollection(shortcut: value, path: nil)
        case "path":
            cwc = openCollection(shortcut: nil, path: value)
        case "id":
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            guard let io = controller.io else { return }
            guard let note = io.getNote(forID: value) else {
                communicateError("Note could not be found with this ID: \(value)")
                return
            }
            controller.select(note: note, position: nil, source: .action)
        default:
            communicateError("Open Query Parameter of '\(label)' not recognized")
        }
    }
    
    func open(link: NotenikLink?, id: String) -> Bool {
        guard let collectionLink = link else { return false }
        guard let wc = juggler.open(link: collectionLink) else { return false }
        if id.count == 0 { return true }
        guard let io = wc.io else { return false }
        guard let note = io.getNote(forID: id) else { return false }
        wc.select(note: note, position: nil, source: .action)
        return true
    }
    
    func processAddCommand(labels: [String], values: [String]) {
        var cwc: CollectionWindowController?
        var note: Note?
        var i = 0
        while i < labels.count {
            processAddParm(label: labels[i],
                           value: values[i],
                           cwc: &cwc,
                           note: &note)
            i += 1
        }
        guard let controller = cwc else { return }
        guard let newNote = note else { return }
        let added = controller.addNewNote(newNote)
        if added == nil {
            communicateError("Note could not be added")
        } else {
            logInfo(msg: "Added new Note titled \(added!.title.value)")
        }
    }
    
    func processAddParm(label: String,
                        value: String,
                        cwc:   inout CollectionWindowController?,
                        note:  inout Note?) {
        switch label {
        case "shortcut":
            cwc = openCollection(shortcut: value, path: nil)
            guard let controller = cwc else { return }
            note = Note(collection: controller.io!.collection!)
        case "path":
            cwc = openCollection(shortcut: nil, path: value)
            guard let controller = cwc else { return }
            note = Note(collection: controller.io!.collection!)
        case "title", "name":
            guard note != nil else { return }
            _ = note!.setTitle(value)
        case "body", "note":
            guard note != nil else { return }
            _ = note!.setBody(value)
        case "date", "due", "completed":
            _ = note!.setDate(value)
        default:
            guard note != nil else { return }
            guard note!.setField(label: label, value: value) else {
                communicateError("Add Query Parameter of '\(label)' not recognized")
                return
            }
        }
    }
    
    func openCollection(shortcut: String?, path: String?) -> CollectionWindowController? {
        var link: NotenikLink?
        if shortcut != nil && shortcut!.count > 0 {
            link = folders.getFolderFor(shortcut: shortcut!)
        }
        if link == nil && path != nil {
            link = folders.getFolderFor(path: path!)
        }
        if link == nil && path != nil {
            var fileURLstr = path!
            if !fileURLstr.starts(with: "file://") {
                fileURLstr = "file://" + path!
            }
            link = NotenikLink(str: fileURLstr, assume: .assumeFile)
        }
        guard let collectionLink = link else { return nil }
        return juggler.open(link: collectionLink)
    }
    
    /// Send an informational message to the log.
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CustomURLActor",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CustomURLActor",
                          level: .error,
                          message: msg)
    }
}
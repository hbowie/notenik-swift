//
//  CustomURLActor.swift
//  Notenik
//
//  Created by Herb Bowie on 5/21/21.
//
//  Copyright © 2021 - 2024 Herb Bowie (https://hbowie.net)
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
    let multi   = MultiFileIO.shared
    let fm = FileManager.default
    
    init() {
        
    }
    
    func act(on customURL: String) -> Bool {
  
        var url: URL? = nil
        url = URL(string: customURL)
        if url == nil {
            let encoded = customURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            if encoded != nil {
                url = URL(string: encoded!)
            }
        }
        guard url != nil else {
            communicateError("Could not fashion a URL from this string: \(customURL)")
            return false
        }
        guard let scheme = url!.scheme else {
            communicateError("Could not extract a scheme from this URL: \(customURL)")
            return false
        }
        guard scheme == NotenikConstants.notenikURLScheme else {
            communicateError("Invalid scheme detected: \(scheme)")
            return false
        }
        guard let command = url!.host else {
            communicateError("Could not extract a command from this URL: \(customURL)")
            return false
        }
        var query = ""
        let possibleQuery = url!.query
        if possibleQuery != nil {
            query = possibleQuery!
        }
        var labels: [String] = []
        var values: [String] = []
        let parameters = query.components(separatedBy: "&")
        for parm in parameters {
            if parm.count > 0 {
                let parmSplit = parm.components(separatedBy: "=")
                guard parmSplit.count == 2 else { continue }
                labels.append(parmSplit[0])
                guard let value = parmSplit[1].removingPercentEncoding else { continue }
                values.append(value)
            }
        }
        switch command {
        case "add":
            processAddCommand(labels: labels, values: values)
        case "help":
            processHelpCommand(labels: labels, values: values)
        case "expand":
            processExpandCommand(labels: labels, values: values)
        case "open":
            processOpenCommand(labels: labels, values: values)
        case "prefs", "settings":
            processPrefsCommand()
        default:
            communicateError("Invalid Command: \(command)")
            return false
        }
        return true
    }
    
    func processHelpCommand(labels: [String], values: [String]) {
        var cwc = juggler.openKB()
        if cwc == nil {
            communicateError("Notenik Knowledge Base could not be opened")
        } else {
            var i = 0
            while i < labels.count {
                processHelpParm(label: labels[i],
                                value: values[i],
                                cwc: &cwc!)
                i += 1
            }
        }
    }
    
    func processHelpParm(label: String,
                         value: String,
                         cwc: inout CollectionWindowController) {
        switch label {
        case "id":
            guard let io = cwc.io else { return }
            guard let note = io.getNote(forID: value) else {
                communicateError("Note could not be found with this ID: \(value)")
                return
            }
            _ = cwc.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                            note: note,
                                            position: nil, row: -1, searchPhrase: nil)
            // cwc.select(note: note, position: nil, source: .action, andScroll: true)
        default:
            communicateError("Help Query Parameter of \(label) not recognized")
        }
    }
    
    func processExpandCommand(labels: [String], values: [String]) {
        
        var cwc: CollectionWindowController?
        var i = 0
        while i < labels.count {
            processExpandParm(label: labels[i],
                              value: values[i],
                              cwc: &cwc)
            i += 1
        }
    }
    
    func processExpandParm(label: String,
                           value: String,
                           cwc:   inout CollectionWindowController?) {
        switch label {
        case "shortcut":
            cwc = openCollection(shortcut: value, path: nil)
        case "path":
            cwc = openCollection(shortcut: nil, path: value)
        case "tag":
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            controller.changeLeftViewVisibility(makeVisible: true)
            var targetTag = value
            if value.starts(with: "#") {
                _ = targetTag.removeFirst()
            }
            controller.expand(forTag: targetTag)
        default:
            communicateError("List Query Parameter of '\(label)' not recognized")
        }
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
            guard let note = io.getNote(knownAs: value) else {
                communicateError("Note could not be found with this ID: \(value)")
                return
            }
            _ = controller.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                                   note: note,
                                                   position: nil, row: -1, searchPhrase: nil)
            // controller.select(note: note, position: nil, source: .action, andScroll: true)
        case "timestamp":
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            guard let io = controller.io else { return }
            guard let collection = io.collection else { return }
            guard collection.hasTimestamp else {
                communicateError("Indicated Collection does not have a Timestamp field")
                return
            }
            guard let note = io.getNote(forTimestamp: value) else {
                communicateError("Note could not be found with this Timestamp: \(value)")
                return
            }
            _ = controller.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                                   note: note,
                                                   position: nil, row: -1, searchPhrase: nil)
            // controller.select(note: note, position: nil, source: .action, andScroll: true)
        case "notepath":
            guard fm.fileExists(atPath: value) else {
                communicateError("Note file could not be located")
                return
            }
            let noteURL = URL(fileURLWithPath: value)
            let folderURL = noteURL.deletingLastPathComponent()
            cwc = openCollection(shortcut: nil, path: folderURL.path)
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            guard let io = controller.io else { return }
            let fileName = noteURL.deletingPathExtension().lastPathComponent
            let noteID = StringUtils.toCommon(fileName)
            guard let note = io.getNote(forID: noteID) else {
                communicateError("Note could not be found with this ID: \(value)")
                return
            }
            _ = controller.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                                   note: note,
                                                   position: nil, row: -1, searchPhrase: nil)
            // controller.select(note: note, position: nil, source: .action, andScroll: true)
        case "attachment":
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            guard let io = controller.io else { return }
            let (note, _) = io.getSelectedNote()
            guard note != nil else { return }
            controller.openAttachment(titled: value)
        case "select":
            guard value == "random" else {
                communicateError("open select value of '\(value)' is not recognized")
                return
            }
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            controller.goToRandomNote(self)
        case "mode":
            guard value == "quotes" else {
                communicateError("open mode value of '\(value)' is not recognized")
                return
            }
            guard let controller = cwc else {
                communicateError("Unable to open desired Collection")
                return
            }
            controller.ensureQuotesMode()
        default:
            communicateError("Open Query Parameter of '\(label)' not recognized")
        }
    }
    
    func open(link: NotenikLink?, id: String) -> Bool {
        guard let collectionLink = link else { return false }
        guard let wc = juggler.open(link: collectionLink) else { return false }
        if id.count == 0 { return true }
        guard let io = wc.io else { return false }
        guard let note = io.getNote(knownAs: id) else { return false }
        _ = wc.viewCoordinator.focusOn(initViewID: "custom-url-actor",
                                       note: note,
                                       position: nil, row: -1, searchPhrase: nil)
       //  wc.select(note: note, position: nil, source: .action, andScroll: true)
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
            link = getFolderForShortcut(shortcut!)
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
            if link != nil {
                link!.determineCollectionType()
            }
        }
        guard let collectionLink = link else { return nil }
        return juggler.open(link: collectionLink)
    }
    
    func getFolderForShortcut(_ shortcut: String) -> NotenikLink? {
        
        let multiEntry = multi.getEntry(shortcut: shortcut)
        if multiEntry == nil {
            let link = folders.getFolderFor(shortcut: shortcut)
            return link
        } else {
            return multiEntry!.link
        }
    }
    
    func processPrefsCommand() {
        juggler.showAppPreferences()
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

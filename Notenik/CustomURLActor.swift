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
        let parameters = query.components(separatedBy: "&")
        var shortcut = ""
        var path = ""
        var id = ""
        for parm in parameters {
            let parmSplit = parm.components(separatedBy: "=")
            guard parmSplit.count == 2 else { continue }
            switch parmSplit[0] {
            case "shortcut":
                shortcut = parmSplit[1]
            case "path":
                path = parmSplit[1]
            case "id":
                id = parmSplit[1]
            default:
                communicateError("Do not recognize query parameter of: \(parmSplit[0])")
            }
        }
        switch command {
        case "open":
            var link: NotenikLink?
            if shortcut.count > 0 {
                link = folders.getFolderFor(shortcut: shortcut)
            }
            if link == nil {
                link = folders.getFolderFor(path: path)
            }
            if link == nil {
                var fileURLstr = path
                if !fileURLstr.starts(with: "file://") {
                    fileURLstr = "file://" + path
                }
                link = NotenikLink(str: fileURLstr, assume: .assumeFile)
            }
            guard open(link: link, id: id) else {
                communicateError("Note could not be opened")
                return false
            }
        default:
            communicateError("Invalid Command: \(command)")
            return false
        }
        return true
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

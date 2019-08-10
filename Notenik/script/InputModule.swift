//
//  InputModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The input module for the scripting engine.
class InputModule: RowConsumer {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    var note: Note!
    
    var notesInput = 0
    var normalization = "0"
    
    init() {

    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .open:
            workspace.inputURL = URL(fileURLWithPath: command.valueWithPathResolved)
            open()
        case .set:
            set()
        default:
            logError("Input Module does not recognize an action of '\(command.action)")
        }
    }
    
    func set() {
        switch command.object {
        case "normalization":
            normalization = command.value
        case "xpltags":
            let xpltags = BooleanValue(command.value)
            workspace.explodeTags = xpltags.isTrue
        case "dirdepth":
            let maxDirDepth = Int(command.value)
            if maxDirDepth != nil {
                workspace.maxDirDepth = maxDirDepth!
                logInfo("Setting maximum directory depth to \(maxDirDepth!)")
            }
        case "":
            break
        default:
            logError("Input Set object of '\(command.object)' is not recognized")
        }
    }
    
    func open() {
        guard let openURL = workspace.inputURL else {
            logError("Input Open couldn't make sense of the location '\(command.valueWithPathResolved)'")
            return
        }
        if command.object.lowercased() == "merge" {
            workspace.list = workspace.fullList
        } else if command.object.count == 0 {
            workspace.collection = NoteCollection()
            if workspace.explodeTags {
                _ = workspace.collection.dict.addDef(LabelConstants.tag)
            }
            workspace.newList()
        } else {
            logError("Input Open command with unrecognized object of '\(command.object)'")
        }

        notesInput = 0
        note = Note(collection: workspace.collection)
        switch command.modifier {
        case "dir":
            openDir(openURL: openURL)
        case "file":
            openDelimited(openURL: openURL)
        case "notenik-defined", "notenik+", "notenik-general":
            openNotenik(openURL: openURL)
        case "notenik-index":
            openNotenikIndex(openURL: openURL)
        case "xlsx":
            openXLSX(openURL: openURL)
        default:
            logError("Input Open modifier of \(command.modifier) not recognized")
        }
        workspace.fullList = workspace.list
    }
    
    func openDelimited(openURL: URL) {
        let reader = DelimitedReader()
        reader.setContext(consumer: self, workspace: workspace)
        _ = reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openDir(openURL: URL) {
        let reader = DirReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.maxDirDepth = workspace.maxDirDepth
        _ = reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openXLSX(openURL: URL) {
        let reader = XLSXReader()
        reader.setContext(consumer: self, workspace: workspace)
        _ = reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openNotenik(openURL: URL) {
        let reader = NoteReader()
        reader.setContext(consumer: self, workspace: workspace)
        _ = reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openNotenikIndex(openURL: URL) {
        let reader = NoteIndexReader()
        reader.setContext(consumer: self, workspace: workspace)
        _ = reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        _ = note.setField(label: label, value: value)
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        if workspace.explodeTags {
            let tags = note.tags
            var xplNotes = 0
            for tag in tags.tags {
                let tagNote = Note(collection: workspace.collection)
                _ = tagNote.setField(label: LabelConstants.tag, value: String(describing: tag))
                note.copyFields(to: tagNote)
                _ = tagNote.setField(label: LabelConstants.tag, value: String(describing: tag))
                workspace.list.append(tagNote)
                notesInput += 1
                xplNotes += 1
            }
            if xplNotes == 0 {
                let tagNote = Note(collection: workspace.collection)
                note.copyFields(to: tagNote)
                _ = tagNote.setField(label: LabelConstants.tag, value: "")
                workspace.list.append(tagNote)
                notesInput += 1
            }
        } else {
            workspace.list.append(note)
            notesInput += 1
        }

        note = Note(collection: workspace.collection)
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "InputModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "InputModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }
}

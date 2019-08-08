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
            break
        }
    }
    
    func set() {
        switch command.object {
        case "normalization":
            normalization = command.value
        case "xpltags":
            let xpltags = BooleanValue(command.value)
            workspace.explodeTags = xpltags.isTrue
        default:
            break
        }
    }
    
    func open() {
        guard let openURL = workspace.inputURL else {
            logError("Input Open couldn't make sense of the location '\(command.valueWithPathResolved)'")
            return
        }
        workspace.collection = NoteCollection()
        if workspace.explodeTags {
            workspace.collection.dict.addDef(LabelConstants.tag)
        }
        workspace.newList()
        notesInput = 0
        note = Note(collection: workspace.collection)
        switch command.modifier {
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
        reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openXLSX(openURL: URL) {
        let reader = XLSXReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openNotenik(openURL: URL) {
        let reader = NoteReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    func openNotenikIndex(openURL: URL) {
        let reader = NoteIndexReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        note.setField(label: label, value: value)
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
                tagNote.setField(label: LabelConstants.tag, value: String(describing: tag))
                note.copyFields(to: tagNote)
                tagNote.setField(label: LabelConstants.tag, value: String(describing: tag))
                workspace.list.append(tagNote)
                notesInput += 1
                xplNotes += 1
            }
            if xplNotes == 0 {
                let tagNote = Note(collection: workspace.collection)
                note.copyFields(to: tagNote)
                tagNote.setField(label: LabelConstants.tag, value: "")
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

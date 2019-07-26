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
    var openURL = URL(fileURLWithPath: "")
    var note: Note!
    var notesInput = 0
    var normalization = "0"
    var explodeTags = false
    
    init() {

    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .open:
            openURL = URL(fileURLWithPath: command.valueWithPathResolved)
            openFile()
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
            explodeTags = xpltags.isTrue
        default:
            break
        }
    }
    
    func openFile() {
        notesInput = 0
        workspace.collection = NoteCollection()
        note = Note(collection: workspace.collection)
        let reader = DelimitedReader(consumer: self)
        reader.read(fileURL: openURL)
        logInfo("\(notesInput) rows read from \(openURL.path)")
        workspace.fullList = workspace.list
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
        workspace.list.append(note)
        notesInput += 1
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

//
//  OutputModule.swift
//  Notenik
//
//  Created by Herb Bowie on 8/9/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class OutputModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    
    init() {
        
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .open:
            workspace.inputURL = URL(fileURLWithPath: command.valueWithPathResolved)
            open()
        default:
            logError("Output Module does not recognize an action of '\(command.action)")
        }
    }
    
    func open() {
        let outputFileName = FileName(command.valueWithPathResolved)
        let outputURL = URL(fileURLWithPath: command.valueWithPathResolved)
        var format = NoteFormat.tabDelimited
        if outputFileName.extLower == "csv" {
            format = .commaSeparated
        }
        let writer = DelimitedWriter(destination: outputURL, format: format)
        writer.open()
        var rowsWritten = 0
        let dict = workspace.collection.dict
        for def in dict.dict {
            writer.write(value: def.value.fieldLabel.properForm)
        }
        writer.endLine()
        for note in workspace.list {
            for entry in dict.dict {
                let def = entry.value
                let field = note.getField(def: def)
                var value = ""
                if field != nil {
                    value = field!.value.value
                }
                writer.write(value: value)
            }
            writer.endLine()
            rowsWritten += 1
        }
        let success = writer.close()
        if success {
            logInfo("\(rowsWritten) rows written to \(outputURL.path)")
        } else {
            logError("Unable to write requested output file")
        }
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "OutputModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "OutputModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }
}

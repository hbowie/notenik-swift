//
//  ScriptEngine.swift
//  Notenik
//
//  Created by Herb Bowie on 7/23/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class ScriptEngine: RowConsumer {
    
    static let scriptExt = ".tcz"
    static let pathPrefix = "#PATH#"
    
    var workspace = ScriptWorkspace()
    var reader: DelimitedReader!
    var rowsRead = 0
    var command = ScriptCommand()
    
    /// Play a Script from a CSV or tab-delimited file
    ///
    /// - Parameter fileURL: The URL of the script to be played.
    /// - Returns: The number of rows read.
    func playScript(fileURL: URL) -> Int {
        logInfo("Starting to play script located at \(fileURL.path)")
        workspace = ScriptWorkspace()
        workspace.scriptIn = fileURL
        rowsRead = 0
        reader = DelimitedReader(consumer: self)
        reader.read(fileURL: fileURL)
        return rowsRead
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        print("\(label): \(value)")
        let labelLower = label.lowercased()
        let valueLower = value.lowercased()
        switch labelLower {
        case "module":
            let module = ScriptModule(rawValue: valueLower)
            if module != nil {
                command.module = module!
            }
        case "action":
            let action = ScriptAction(rawValue: valueLower)
            if action != nil {
                command.action = action!
            }
        case "modifier":
            command.modifier = value
        case "object":
            command.object = value
        case "value":
            command.value = value
            if value.hasPrefix("#PATH#") {
                let scriptFileName = FileName(workspace.scriptIn!)
                let scriptFolderName = FileName(scriptFileName.path)
                command.valueWithPathResolved = scriptFolderName.resolveRelative(path: String(value.dropFirst(ScriptEngine.pathPrefix.count)))
                print("  - Value with path resolved = \(command.valueWithPathResolved)")
            } else {
                command.valueWithPathResolved = value
            }
        default:
            logError("Column heading of \(label) not recognized as valid within a script file")
        }
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        rowsRead += 1
        switch command.module {
        case .input:
            let input = InputModule()
            input.playCommand(workspace: workspace, command: command)
        default:
            break
        }
        command = ScriptCommand()
        print(" ")
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log. 
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .error,
                          message: msg)
        
    }

}

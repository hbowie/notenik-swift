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
    var logLine = ""
    var pendingErrors = ""
    var consumingFields = true
    
    /// Play a Script from a CSV or tab-delimited file
    ///
    /// - Parameter fileURL: The URL of the script to be played.
    /// - Returns: The number of rows read.
    func playScript(fileURL: URL) -> Int {
        workspace = ScriptWorkspace()
        workspace.scriptIn = fileURL
        logInfo("Starting to play script located at \(fileURL.path) on \(DateUtils.shared.dateTimeToday)")
        rowsRead = 0
        reader = DelimitedReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.read(fileURL: fileURL)
        logInfo("Script execution complete on \(DateUtils.shared.dateTimeToday)")
        return rowsRead
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        let labelLower = label.lowercased()
        let valueLower = value.lowercased()
        switch labelLower {
        case "module":
            logLine.append(value)
            var module = ScriptModule(rawValue: valueLower)
            if module == nil && value.hasPrefix("<!-- ") {
                module = .comment
            } else
            if module != nil {
                command.module = module!
            } else {
                logError("Module value of '\(value)' is not recognized")
            }
        case "action":
            logLine.append("," + value)
            let action = ScriptAction(rawValue: valueLower)
            if action != nil {
                command.action = action!
            } else {
                logError("Action value of '\(value)' is not recognized")
            }
        case "modifier":
            logLine.append("," + value)
            command.modifier = value
        case "object":
            logLine.append("," + value)
            command.object = value
        case "value":
            logLine.append("," + value)
            command.value = value
            if value.hasPrefix("#PATH#") {
                let scriptFileName = FileName(workspace.scriptIn!)
                let scriptFolderName = FileName(scriptFileName.path)
                command.valueWithPathResolved = scriptFolderName.resolveRelative(path: String(value.dropFirst(ScriptEngine.pathPrefix.count)))
            } else {
                command.valueWithPathResolved = value
            }
        default:
            logError("Column heading of '\(label)' not recognized as valid within a script file")
        }
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        rowsRead += 1
        workspace.writeLineToLog("Playing Script Command: " + logLine)
        workspace.scriptLog.append(pendingErrors)
        pendingErrors = ""
        consumingFields = false
        switch command.module {
        case .input:
            let input = InputModule()
            input.playCommand(workspace: workspace, command: command)
        case .filter:
            let filter = FilterModule()
            filter.playCommand(workspace: workspace, command: command)
        case .sort:
            let sorter = SortModule()
            sorter.playCommand(workspace: workspace, command: command)
        case .template:
            let template = TemplateModule()
            template.playCommand(workspace: workspace, command: command)
        default:
            break
        }
        command = ScriptCommand()
        logLine = ""
        consumingFields = true
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log. 
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptEngine",
                          level: .error,
                          message: msg)
        if consumingFields {
            pendingErrors.append(workspace.formatError(msg) + "\n")
        } else {
            workspace.writeErrorToLog(msg)
        }
    }

}

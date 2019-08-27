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

/// The core module for playing and recording scripts, and
/// executing script commands.
class ScriptEngine: RowConsumer {
    
    var lastScriptURL: URL?
    
    var lastCommandModuleStr = "script"
    
    var workspace = ScriptWorkspace()
    
    var command   = ScriptCommand()
    
    var reader:     DelimitedReader!
    var rowsRead  = 0
    
    static let scriptExt = ".tcz"
    static let pathPlaceHolder = "#PATH#"
    
    let input    = InputModule()
    let filter   = FilterModule()
    let sorter   = SortModule()
    let template = TemplateModule()
    let output   = OutputModule()
    
    init() {
 
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        workspace.holdErrors()
        let labelLower = label.lowercased()
        let valueLower = value.lowercased()
        switch labelLower {
        case "module":
            let possibleCommand = getCommand(moduleStr: value)
            if possibleCommand != nil {
                command = possibleCommand!
            }
        case "action":
            command.setAction(value: valueLower)
        case "modifier":
            command.modifier = value
        case "object":
            command.object = value
        case "value":
            command.value = value
            if value.hasPrefix("#PATH#") {
                let scriptFileName = FileName(workspace.scriptURL!)
                let scriptFolderName = FileName(scriptFileName.path)
                command.valueWithPathResolved = scriptFolderName.resolveRelative(path: String(value.dropFirst(ScriptEngine.pathPlaceHolder.count)))
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
        playCommand(command)
        command = ScriptCommand(workspace: workspace)
    }
    
    /// Play a script command -- all script commands should be executed
    /// through this method.
    func playCommand(_ command: ScriptCommand) {
        
        var verb = "Executing"
        if workspace.scriptingStage == .playing {
            verb = "Playing"
        }
        workspace.writeLineToLog("\(verb) Script Command: " + String(describing: command))
        workspace.releaseErrors()
        if workspace.scriptingStage == .recording && command.module != .script {
            workspace.writeCommandToScriptWriter(command)
        }
        switch command.module {
        case .script:
            playScriptCommand(command)
        case .input:
            input.playCommand(workspace: workspace, command: command)
        case .filter:
            filter.playCommand(workspace: workspace, command: command)
        case .sort:
            sorter.playCommand(workspace: workspace, command: command)
        case .template:
            template.playCommand(workspace: workspace, command: command)
        case .output:
            output.playCommand(workspace: workspace, command: command)
        default:
            break
        }
    }
    
    /// Play a command to be executed by the Scripting Engine itself.
    func playScriptCommand(_ command: ScriptCommand) {
        if command.action == .open && command.modifier == "input" {
            scriptOpenInput(command)
        } else if command.action == .play {
            scriptPlay(command)
        } else if command.action == .open && command.modifier == "output" {
            scriptOpenOutput(command)
        } else if command.action == .record {
            scriptRecord(command)
        } else if command.action == .stop {
            scriptStopRecording(command)
        }
    }
    
    /// Open a script file as input.
    func scriptOpenInput(_ command: ScriptCommand) {
        workspace.scriptURL = command.valueURL
        workspace.scriptingStage = .inputSupplied
    }
    
    /// Play a script file that has previously been opened.
    func scriptPlay(_ command: ScriptCommand) {
        if workspace.scriptingStage != .inputSupplied && lastScriptURL != nil {
            workspace.scriptingStage = .inputSupplied
            if workspace.scriptURL == nil {
                workspace.scriptURL = lastScriptURL
            }
        }
        guard workspace.scriptingStage == .inputSupplied else {
            logError("Script Play command encountered with no preceding Script Open Input")
            return
        }
        guard let scriptURL = workspace.scriptURL else {
            logError("Script Play command encountered but no valid script file specified")
            return
        }
        logInfo("Starting to play script located at \(scriptURL.path) on \(DateUtils.shared.dateTimeToday)")
        workspace.scriptingStage = .playing
        rowsRead = 0
        reader = DelimitedReader()
        reader.setContext(consumer: self, workspace: workspace)
        reader.read(fileURL: scriptURL)
        logInfo("Script execution complete on \(DateUtils.shared.dateTimeToday)")
        lastScriptURL = workspace.scriptURL
    }
    
    /// Open an output script file.
    func scriptOpenOutput(_ command: ScriptCommand) {
        workspace.scriptURL = command.valueURL
        workspace.scriptingStage = .outputSupplied
    }
    
    /// Start recording a script to an output file that has already
    /// been opened.
    func scriptRecord(_ command: ScriptCommand) {
        guard workspace.scriptingStage == .outputSupplied else {
            logError("Script Record command encountered with no preceding Script Open Output")
            return
        }
        guard let scriptURL = workspace.scriptURL else {
            logError("Script Record command encountered but no valid script file specified")
            return
        }
        logInfo("Starting to record script located at \(scriptURL.path) on \(DateUtils.shared.dateTimeToday)")
        workspace.openScriptWriter(fileURL: scriptURL)
    }
    
    func scriptStopRecording(_ command: ScriptCommand) {
        guard workspace.scriptingStage == .recording else {
            logError("Cannot Stop Script Recording since None is in Progress")
            return
        }
        lastScriptURL = workspace.scriptURL
        workspace.closeScriptWriter()
    }
    
    /// Factory method to create a command populated with the given module.
    ///
    /// - Parameter moduleStr: A string naming the desired module.
    /// - Returns: Either the command with the specified module, or
    ///            nil if the module name was invalid.
    func getCommand(moduleStr: String) -> ScriptCommand? {
        if moduleStr != lastCommandModuleStr && moduleStr == "script" {
            newWorkspace()
        }
        let command = ScriptCommand(workspace: workspace)
        let ok = command.setModule(value: moduleStr)
        if ok {
            lastCommandModuleStr = moduleStr
            return command
        }
        return nil
    }
    
    func newWorkspace() {
        workspace = ScriptWorkspace()
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
        workspace.writeErrorToLog(msg)
    }

}

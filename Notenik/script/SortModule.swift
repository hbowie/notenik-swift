//
//  SortModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class SortModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    
    init() {
        
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .add:
            addField()
        case .clear:
            clear()
        case .set:
            if command.object == "params" {
                setParams()
            } else {
                logError("Object value of '\(command.object)' not valid for Sort Set command")
            }
        default:
            logError("Sort Module does not recognize \(command.action) as a valid action")
        }
    }
    
    func addField() {
        let modLower = command.modifier.lowercased()
        var ascending = true
        if modLower.hasPrefix("d") {
            ascending = false
        }
        let newField = SortField(dict: workspace.collection.dict,
                                 label: command.object,
                                 ascending: ascending)
        workspace.pendingFields.append(newField)
        newField.logField()
    }
    
    func clear() {
        workspace.pendingFields = []
    }
    
    func setParams() {
        workspace.collection.customFields = workspace.pendingFields
        workspace.collection.sortParm = .custom
        workspace.list.sort()
    }

    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SortModule",
                          level: .info,
                          message: msg)
        workspace.writeLineToLog(msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SortModule",
                          level: .error,
                          message: msg)
        workspace.writeErrorToLog(msg)
    }
}

//
//  FilterModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class FilterModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    var openURL = URL(fileURLWithPath: "")
    
    init() {
    
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .add:
            addFilter()
        case .set:
            if command.object == "params" {
                setParams()
            }
        default:
            break
        }
    }
    
    func addFilter() {
        let newRule = FilterRule(dict: workspace.collection.dict,
                                label: command.object,
                                   op: command.modifier,
                                   to: command.value)
        workspace.pendingRules.append(newRule)
        newRule.logRule()
    }
    
    func setParams() {
        workspace.currentRules = workspace.pendingRules
        workspace.list = NotesList()
        for note in workspace.fullList {
            var selected = true
            for rule in workspace.currentRules {
                let field = note.getField(def: rule.field)
                if field != nil {
                    let passed = rule.op.compare(field!.value, rule.to)
                    if !passed {
                        selected = false
                    }
                }
            }
            if selected {
                workspace.list.append(note)
            }
        }
        logInfo("\(workspace.list.count) Notes passed the filter rules")
        logInfo("\(workspace.fullList.count - workspace.list.count) Notes were filtered out")
    }
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FilterModule",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FilterModule",
                          level: .error,
                          message: msg)
        
    }
}

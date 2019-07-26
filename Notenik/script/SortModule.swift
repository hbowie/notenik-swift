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
        case .set:
            if command.object == "params" {
                setParams()
            }
        default:
            break
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
    
    func setParams() {

        workspace.collection.customFields = workspace.pendingFields
        workspace.collection.sortParm = .custom
        workspace.list.sort()
    }

}

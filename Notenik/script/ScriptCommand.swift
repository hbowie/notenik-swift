//
//  ScriptCommand.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One command to be executed by the Scripting Engine.
class ScriptCommand: CustomStringConvertible {
    
    var workspace: ScriptWorkspace?
    
    var line      = ""
    
    var module:   ScriptModule = .blank
    var action:   ScriptAction = .blank
    var modifier  = ""
    var object    = ""
    var value     = ""
    var valueWithPathResolved = ""
    
    init() {
        
    }
    
    convenience init(workspace: ScriptWorkspace?) {
        self.init()
        self.workspace = workspace
    }
    
    var description: String {
        var desc = ""
        if module == .comment {
            desc = line
        } else if module != .blank {
            desc = csv
        }
        return desc
    }
    
    var csv: String {
        return "\(module),\(action),\(modifier),\(object),\(value)"
    }
    
    var valueURL: URL {
        return URL(fileURLWithPath: valueWithPathResolved)
    }
    
    func setModule(value: String) -> Bool {
        let valueLower = value.lowercased()
        let module = ScriptModule(rawValue: valueLower)
        if module == nil && value.hasPrefix("<!-- ") {
            self.module = .comment
            line = value
        } else if module != nil {
            self.module = module!
        } else {
            logError("Module value of '\(value)' is not recognized")
            return false
        }
        return true
    }
    
    func setAction(value: String) {
        let valueLower = value.lowercased()
        let action = ScriptAction(rawValue: valueLower)
        if action != nil {
            self.action = action!
        } else {
            logError("Action value of '\(value)' is not recognized")
        }
    }
    
    func setValue(fileURL: URL) {
        value = fileURL.path
        valueWithPathResolved = fileURL.path
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "ScriptCommand",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
}

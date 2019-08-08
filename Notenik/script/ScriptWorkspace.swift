//
//  ScriptWorkspace.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A workspace to be shared between the Script Engine and its various modules. 
class ScriptWorkspace {
    
    var scriptIn:     URL?
    var collection  = NoteCollection()
    
    var inputURL:     URL?
    var explodeTags = false
    
    var list        = NotesList()
    var fullList    = NotesList()
    
    var pendingRules: [FilterRule] = []
    var currentRules: [FilterRule] = []
    
    var pendingFields: [SortField] = []
    
    var template = Template()
    
    var webRootPath  = ""
    
    var scriptLog   = ""
    
    func newList() {
        list = NotesList()
        fullList = NotesList()
    }
    
    func writeErrorToLog(_ msg: String) {
        writeLineToLog(formatError(msg))
    }
    
    func formatError(_ msg: String) -> String {
        return "  ## ERROR: " + msg
    }
    
    func writeLineToLog(_ line: String) {
        scriptLog.append(line + "\n")
    }
}

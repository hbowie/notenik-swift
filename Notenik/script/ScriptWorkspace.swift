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
    
    var parentPath = ""
    
    var scriptURL:     URL?
    var collection  = NoteCollection()
    
    var inputURL:     URL?
    var explodeTags = false
    var maxDirDepth = 1
    
    var list        = NotesList()
    var fullList    = NotesList()
    
    var pendingRules: [FilterRule] = []
    var currentRules: [FilterRule] = []
    
    var pendingFields: [SortField] = []
    
    var template = Template()
    
    var webRootPath  = ""
    
    var pendingErrors = ""
    var holdingErrors = false
    
    var scriptLog   = ""
    
    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        parentPath = home.path
    }
    
    var parentURL: URL {
        return URL(fileURLWithPath: parentPath)
    }
    
    func newList() {
        list = NotesList()
        fullList = NotesList()
    }
    
    func holdErrors() {
        holdingErrors = true
    }
    
    func releaseErrors() {
        scriptLog.append(pendingErrors)
        holdingErrors = false
        pendingErrors = ""
    }
    
    func writeErrorToLog(_ msg: String) {
        if holdingErrors {
            pendingErrors.append(formatError(msg) + "\n")
        } else {
            writeLineToLog(formatError(msg))
        }
    }
    
    func formatError(_ msg: String) -> String {
        return "  ## ERROR: " + msg
    }
    
    func writeLineToLog(_ line: String) {
        scriptLog.append(line + "\n")
    }
}

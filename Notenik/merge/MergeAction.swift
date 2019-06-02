//
//  MergeAction.swift
//  Notenik
//
//  Created by Herb Bowie on 5/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object representing one scripted NoteMerge action to be taken. 
class MergeAction {
    
    var module:   MergeActionModule = .input
    var verb:     MergeActionVerb = .open
    var modifier: MergeActionModifier = .file
    var object    = ""
    var value     = ""
    var absolutePath = ""
    
    var moduleStr: String {
        get {
            return module.rawValue
        }
        set {
            let possibleModule = MergeActionModule(rawValue: newValue.lowercased())
            if possibleModule != nil {
                module = possibleModule!
            } else {
                print("Module value of \(newValue) not recognized")
            }
        }
    }
    
    var verbStr: String {
        get {
            return verb.rawValue
        }
        set {
            let possibleVerb = MergeActionVerb(rawValue: newValue.lowercased())
            if possibleVerb != nil {
                verb = possibleVerb!
            } else {
                print("Verb value of \(newValue) not recognized")
            }
        }
    }
    
    var modifierStr: String {
        get {
            return modifier.rawValue
        }
        set {
            let possibleModifier = MergeActionModifier(rawValue: newValue.lowercased())
            if possibleModifier != nil {
                modifier = possibleModifier!
            } else {
                print("Modifier value of \(newValue) not recognized")
            }
        }
    }
    
    func setAbsolutePath(scriptPath: String) {
        absolutePath = ""
        var i = 0
        var word = ""
        var url = URL(fileURLWithPath: scriptPath)
        var pathFound = false
        for char in value {
            word.append(char)
            let wordLower = word.lowercased()
            if wordLower == "#path#" && i == 5 {
                pathFound = true
                word = ""
            } else if pathFound && word == "../" {
                url = url.deletingLastPathComponent()
                word = ""
            }
            i += 1
        }
        if pathFound {
            if word.count > 0 {
                url = url.appendingPathComponent(word)
            }
            absolutePath = url.path
        } else {
            absolutePath = value
        }
        print("Set absolute path to \(absolutePath)")
    }
}

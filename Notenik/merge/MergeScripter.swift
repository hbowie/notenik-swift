//
//  MergeScripter.swift
//  Notenik
//
//  Created by Herb Bowie on 5/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MergeScripter: RowConsumer {
    
    var scriptPath = ""
    
    var actions = [MergeAction]()
    
    var action = MergeAction()
    
    var io: NotenikIO = BunchIO()
    
    var inputModule: MergeInput
    
    init() {
        inputModule = MergeInput(notenikIO: io)
    }
    
    func play(scriptPath: String) {
        let scriptURL = URL(fileURLWithPath: scriptPath)
        play(scriptURL: scriptURL)
    }
    
    func play(scriptURL: URL) {
        let scriptFolder = scriptURL.deletingLastPathComponent()
        scriptPath = scriptFolder.path
        actions = []
        action = MergeAction()
        let reader = DelimitedReader(consumer: self)
        let actionsRead = reader.read(fileURL: scriptURL)
        print("\(actionsRead) Actions Read")
        
        var lastActionInput = false
        for action in actions {
            switch action.module {
            case .input:
                if !lastActionInput {
                    io = BunchIO()
                    inputModule = MergeInput(notenikIO: io)
                }
                inputModule.act(action)
                lastActionInput = true
            default:
                lastActionInput = false
                print("No module for \(action.module)")
            }
        }
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        let labelLower = label.lowercased()
        switch labelLower {
        case "module":
            action.moduleStr = value
        case "action":
            action.verbStr = value
        case "modifier":
            action.modifierStr = value
        case "object":
            action.object = value
        case "value":
            action.value = value
        default:
            print("Not sure what to do with field labeled \(label)")
        }
    }
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        action.setAbsolutePath(scriptPath: scriptPath)
        actions.append(action)
        action = MergeAction()
    }
}

//
//  MergeInput.swift
//  Notenik
//
//  Created by Herb Bowie on 6/1/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MergeInput {
    
    var io: NotenikIO
    
    var normalization = 0
    var explodeTags   = false
    
    init(notenikIO: NotenikIO) {
        io = notenikIO
    }
    
    func act(_ action: MergeAction) {
        guard action.module == .input else { return }
        switch action.verb {
        case .set:
            set(action)
        case .open:
            open(action)
        default:
            print("Unrecognized Input Action (aka Verb) of \(action.verb)")
        }
    }
    
    func set(_ action: MergeAction) {
        if action.object == "normalization" {
            let possibleNormalization = Int(action.value)
            if possibleNormalization != nil {
                normalization = possibleNormalization!
            }
        } else if action.object == "xpltags" {
            let possibleXpltags = Bool(action.value)
            if possibleXpltags != nil {
                explodeTags = possibleXpltags!
            }
        } else {
            print("Unrecognized Input Set Object of \(action.object)")
        }
    }
    
    func open(_ action: MergeAction) {
        switch action.modifier {
        case .notenikPlus:
            let inputIO = FileIO()
            let inputRealm = inputIO.getDefaultRealm()
            inputRealm.path = ""
            let inputCollection = inputIO.openCollection(realm: inputRealm, collectionPath: action.absolutePath)
            if inputCollection == nil {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "MergeInput",
                                  level: .error,
                                  message: "Problems opening the collection at " + action.absolutePath)
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "MergeInput",
                                  level: .info,
                                  message: "Collection successfully opened: \(action.absolutePath)")
                inputCollection!.readOnly = true
            }
            
        default:
            print("Don't yet know how to open \(action.modifier)")
        }
    }
}

//
//  FieldRenameParms.swift
//  Notenik
//
//  Created by Herb Bowie on 12/12/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class FieldRenameParms {
    var action: FieldRenameAction = .rename
    var existingFieldLabel = ""
    var newFieldLabel = ""
    var newFieldType = ""
    var typeConfigText = ""
    var newFieldDefault = ""
    
    var addOrRename: Bool {
        switch action {
        case .remove:
            return false
        default:
            return true
        }
    }
    
    var removeOrRename: Bool {
        switch action {
        case .add:
            return false
        default:
            return true
        }
    }
    
    var remove: Bool { return action == .remove }
    var add:    Bool { return action == .add }
    var rename: Bool { return action == .rename }
    
    public init() {
        
    }
    
    func display() {
        print("FieldRenameParms")
        print("  - action: \(action)")
        print("  - existing field label: \(existingFieldLabel)")
        print("  - new field label:      \(newFieldLabel)")
        print("  - new field type:       \(newFieldType)")
        print("  - new type config:      \(typeConfigText)")
    }
}

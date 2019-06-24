//
//  NoteField.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class NoteField {
    
    var def   : FieldDefinition
    var value : StringValue
    
    init() {
        def = FieldDefinition()
        value = StringValue()
    }
    
    convenience init(def: FieldDefinition, value: StringValue) {
        self.init()
        self.def = def
        self.value = value
    }
    
    convenience init(def: FieldDefinition, statusConfig: StatusValueConfig) {
        self.init()
        self.def = def
        value = ValueFactory.getValue(type: def.fieldType, value: "", statusConfig: statusConfig)
    }
    
    convenience init(def: FieldDefinition, value: String, statusConfig: StatusValueConfig) {
        self.init()
        self.def = def
        self.value = ValueFactory.getValue(type: def.fieldType, value: value, statusConfig: statusConfig)
    }
    
    convenience init(label: String, value: String, statusConfig: StatusValueConfig) {
        self.init()
        let fieldLabel = FieldLabel(label)
        self.def = FieldDefinition(label: fieldLabel)
        self.value = ValueFactory.getValue(type: def.fieldType, value: value, statusConfig: statusConfig)
    }
    
    func display() {
        print("NoteField.display")
        print("FieldDefinition has label of \(def.fieldLabel)")
        print("Value has type of \(type(of: value))")
        print("Value has value of \(value.value)")
    }
}

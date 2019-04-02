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
    
    convenience init(def : FieldDefinition) {
        self.init()
        self.def = def
        value = ValueFactory.getValue(type: def.fieldType, value: "")
    }
    
    convenience init(def: FieldDefinition, value: String) {
        self.init()
        self.def = def
        self.value = ValueFactory.getValue(type: def.fieldType, value: value)
    }
    
    convenience init(label : String, value: String) {
        self.init()
        let fieldLabel = FieldLabel(label)
        self.def = FieldDefinition(label: fieldLabel)
        self.value = ValueFactory.getValue(type: def.fieldType, value: value)
    }
}

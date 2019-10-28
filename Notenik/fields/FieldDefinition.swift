//
//  FieldDefinition.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The label used to identify this field, along with the field type.
class FieldDefinition {
    
    var typeCatalog: AllTypes!
    
    var fieldLabel:  FieldLabel = FieldLabel()
    var fieldType:   AnyType = StringType()
    
    /// Initialize with no parameters, defaulting to a simple String type.
    init() {
        
    }
    
    init(typeCatalog: AllTypes) {
        self.typeCatalog = typeCatalog
        fieldLabel.set("unknown")
        fieldType = typeCatalog.assignType(label: fieldLabel, type: nil)
    }
    
    /// Initialize with a string label and guess the type
    convenience init(typeCatalog: AllTypes, label: String) {
        self.init(typeCatalog: typeCatalog)
        fieldLabel.set(label)
        fieldType = typeCatalog.assignType(label: fieldLabel, type: nil)
    }
    
    /// Initialize with a FieldLabel object
    convenience init (typeCatalog: AllTypes, label: FieldLabel) {
        self.init(typeCatalog: typeCatalog)
        self.fieldLabel = label
        fieldType = typeCatalog.assignType(label: label, type: nil)
    }
    
    /// Initialize with a string label and an integer type
    convenience init (typeCatalog: AllTypes, label: String, type: String) {
        self.init(typeCatalog: typeCatalog)
        fieldLabel.set(label)
        fieldType = typeCatalog.assignType(label: fieldLabel, type: type)
    }
    
    func display() {
        print("FieldDefinition")
        fieldLabel.display()
        print("Field Type String: \(fieldType.typeString)")
    }
}

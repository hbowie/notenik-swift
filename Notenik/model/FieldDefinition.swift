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

class FieldDefinition {
    
    var fieldLabel : FieldLabel = FieldLabel()
    var fieldType  : FieldType  = .defaultType
    
    init() {
        
    }
    
    /// Initialize with a string label and guess the type
    convenience init(_ label: String) {
        self.init()
        fieldLabel.set(label)
        guessFieldType()
    }
    
    /// Initialize with a FieldLabel object
    convenience init (label: FieldLabel) {
        self.init()
        self.fieldLabel = label
        guessFieldType()
    }
    
    /// Initialize with a string label and an integer type
    convenience init (label: String, type: Int) {
        self.init()
        fieldLabel.set(label)
        fieldType = FieldType(rawValue: type)!
    }
    
    /// Derive field type from label
    func guessFieldType() {
        fieldType = FieldType.defaultType
        switch fieldLabel.commonForm {
        case "author", "by", "creator":
            fieldType = FieldType.author
        case "body", "teaser":
            fieldType = FieldType.longText
        case "code":
            fieldType = FieldType.code
        case "date":
            fieldType = FieldType.date
        case "dateadded":
            fieldType = FieldType.dateAdded
        case "index":
            fieldType = FieldType.index
        case "link", "url":
            fieldType = FieldType.link
        case "rating", "priority":
            fieldType = FieldType.rating
        case "recurs", "every":
            fieldType = FieldType.recurs
        case "seq", "sequence", "rev", "revision", "version":
            fieldType = FieldType.seq
        case "status":
            fieldType = FieldType.status
        case "tags", "keywords", "category", "categories":
            fieldType = FieldType.tags
        case "title":
            fieldType = FieldType.title
        case "type":
            fieldType = FieldType.string
        case "work", "work title":
            fieldType = FieldType.work
        case "worktype":
            fieldType = FieldType.pickFromList
        default:
            if fieldLabel.commonForm.range(of: "date") != nil {
                fieldType = FieldType.date
            } else if fieldLabel.commonForm.range(of: "link") != nil {
                fieldType = FieldType.link
            } else {
                fieldType = FieldType.defaultType
            }
        }
    }
    
}

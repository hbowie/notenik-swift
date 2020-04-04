//
//  SortField.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class SortField {
    
    var field = FieldDefinition()
    var ascending = true
    
    init(field: FieldDefinition, ascending: Bool) {
        self.field = field
        self.ascending = ascending
    }
    
    init(dict: FieldDictionary, label: String, ascending: Bool) {
        
        let possibleField = dict.getDef(label)
        if possibleField != nil {
            self.field = possibleField!
        } else {
            logError("Sort field label of \(label) could not be found in input source")
        }
        
        self.ascending = ascending
    }
    
    func logField() {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SortField",
                          level: .info,
                          message: "Creating sort field: \(field.fieldLabel.properForm) \(ascending ? "ascending" : "descending")")
    }
    
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "SortField",
                          level: .error,
                          message: msg)
    }
}

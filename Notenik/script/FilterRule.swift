//
//  FilterRule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class FilterRule {
    
    var field = FieldDefinition()
    var op    = FieldComparisonOperator()
    var to    = ""
    
    init(field: FieldDefinition, op: FieldComparisonOperator, to: String) {
        self.field = field
        self.op = op
        self.to = to
    }
    
    init(dict: FieldDictionary, label: String, op: String, to: String) {
        
        let possibleField = dict.getDef(label)
        if possibleField != nil {
            self.field = possibleField!
        } else {
            logError("Field label of \(label) could not be found in input source")
        }
        
        self.op = FieldComparisonOperator(op)
        
        self.to = to
    }
    
    func logRule() {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
            category: "FilterRule",
            level: .info,
            message: "Creating filter rule: \(field.fieldLabel.properForm) \(op) \(to)")
    }
    
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FilterRule",
                          level: .error,
                          message: msg)
    }
}

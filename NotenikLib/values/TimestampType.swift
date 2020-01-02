//
//  TimestampType.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class TimestampType: AnyType {

    override init() {
         
        super.init()
        
        /// A string identifying this particular field type.
        typeString  = "timestamp"
        
        /// The proper label typically assigned to fields of this type.
        properLabel = "Timestamp"
        
        /// The common label typically assigned to fields of this type.
        commonLabel = "timestamp"
    }

    /// A factory method to create a new value of this type with no initial value.
    override func createValue() -> StringValue {
        return TimestampValue()
    }

    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    override func createValue(_ str: String) -> StringValue {
        return TimestampValue(str)
    }
    
}

//
//  ValueFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Factory class for creating various types of field values
class ValueFactory {
    
    /// Given a field type and a String, return the appropriate field value
    static func getValue (type: FieldType, value: String, statusConfig: StatusValueConfig) -> StringValue {
        switch type {
        case .string:
            return StringValue(value)
        case .title:
            return TitleValue(value)
        case .longText:
            return LongTextValue(value)
        case .tags:
            return TagsValue(value)
        case .link:
            return LinkValue(value)
        case .label:
            return StringValue(value)
        case .author:
            return AuthorValue(value)
        case .date:
            return DateValue(value)
        case .rating:
            return RatingValue(value)
        case .status:
            return StatusValue(str: value, config: statusConfig)
        case .seq:
            return SeqValue(value)
        case .index:
            return IndexValue(value)
        case .recurs:
            return RecursValue(value)
        case .code:
            return LongTextValue(value)
        case .dateAdded:
            return DateValue(value)
        case .work:
            return StringValue(value)
        case .pickFromList:
            return StringValue(value)
        default:
            return StringValue(value)
        }
    }
    
    /// Given just a data value, return value type that is the best fit. 
    static func getValue(value: String) -> StringValue {
        if value.count == 0 {
            return StringValue(value)
        } else {
            let possibleInt = Int(value)
            if possibleInt != nil {
                return IntValue(value)
            } else {
                return StringValue(value)
            }
        }
    }
}

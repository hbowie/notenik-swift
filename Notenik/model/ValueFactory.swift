//
//  ValueFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Factory class for creating various types of field values
class ValueFactory {
    
    /// Given a field type and a String, return the appropriate field value
    static func getValue (type: FieldType, value : String) -> StringValue {
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
            return StatusValue(value)
        case .seq:
            return SeqValue(value)
        case .index:
            return StringValue(value)
        case .recurs:
            return RecursValue(value)
        case .code:
            return LongTextValue()
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
}

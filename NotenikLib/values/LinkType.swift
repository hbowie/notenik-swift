//
//  LinkType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LinkType: AnyType {
    
    override init() {
        
        super.init()
        
         /// A string identifying this particular field type.
         typeString  = "link"
         
         /// The proper label typically assigned to fields of this type.
         properLabel = "Link"
         
         /// The common label typically assigned to fields of this type.
         commonLabel = "link"
    }
     
     /// A factory method to create a new value of this type with no initial value.
     override func createValue() -> StringValue {
         return LinkValue()
     }
     
     /// A factory method to create a new value of this type with the given value.
     /// - Parameter str: The value to be used to populate the field with a value.
     override func createValue(_ str: String) -> StringValue {
         let link = LinkValue(str)
         return link
     }
     
     /// Is this type suitable for a particular field, given its label and type (if any)?
     /// - Parameter label: The label.
     /// - Parameter type: The type string (if one is available)
     override func appliesTo(label: FieldLabel, type: String?) -> Bool {
         if type == nil || type!.count == 0 {
            return (label.commonForm == commonLabel || label.commonForm == "url" || label.commonForm.range(of: "link") != nil)
         } else {
             return (type! == typeString)
         }
     }
}

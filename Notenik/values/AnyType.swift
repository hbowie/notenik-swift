//
//  AnyType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The requirements that must be fulfilled for any field type class. 
protocol AnyType {
    
    /// A string identifying this particular field type.
    var typeString:  String { get }
    
    /// The proper label typically assigned to fields of this type.
    var properLabel: String { get }
    
    /// The common label typically assigned to fields of this type.
    var commonLabel: String { get }
    
    /// A factory method to create a new value of this type with no initial value.
    func createValue() -> StringValue
    
    /// A factory method to create a new value of this type with the given value.
    /// - Parameter str: The value to be used to populate the field with a value.
    func createValue(_ str: String) -> ArtistValue
    
    /// Is this type suitable for a particular field, given its label and type (if any)?
    /// - Parameter label: The label.
    /// - Parameter type: The type string (if one is available)
    func appliesTo(label: FieldLabel, type: String?) -> Bool
    
}

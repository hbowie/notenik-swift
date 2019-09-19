//
//  ArtistValue.swift
//  Notenik
//
//  Created by Herb Bowie on 9/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The name of an artist, which might be an individual or a group.
class ArtistValue: StringValue {
    
    var compKey = ""
    
    /// Set a new value for the object
    override func set(_ value: String) {
        self.value = value
        let valueLower = value.lowercased()
        if valueLower.starts(with: "the ") {
            let index = valueLower.index(valueLower.startIndex, offsetBy: 4)
            let withoutThe = valueLower[index...]
            compKey = String(withoutThe)
        } else {
            compKey = valueLower
        }
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return compKey
    }
}

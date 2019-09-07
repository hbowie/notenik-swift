//
//  WorkTitleValue.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WorkTitleValue: StringValue {
    
    override init() {
        super.init()
    }
    
    /// Initialize with a String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
}

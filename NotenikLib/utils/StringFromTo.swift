//
//  StringFromTo.swift
//  Notenik
//
//  Created by Herb Bowie on 6/10/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class StringFromTo {
    
    var from = ""
    var to = ""
    
    init() {
        
    }
    
    convenience init(from: String, to: String) {
        self.init()
        self.from = from
        self.to = to
    }
}

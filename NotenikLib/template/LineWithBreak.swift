//
//  LineWithBreak.swift
//  Notenik
//
//  Created by Herb Bowie on 6/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single line, with a boolean to indicate whether there is to be
/// a line break afterwards.
class LineWithBreak {
    
    var line = ""
    var lineBreak = true
    
    convenience init(_ line: String) {
        self.init()
        self.line = line
    }
    
    convenience init(_ line: String, lineBreak: Bool) {
        self.init()
        self.line = line
        self.lineBreak = lineBreak
    }
}

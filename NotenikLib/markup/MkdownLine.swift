//
//  MkdownLine.swift
//  Notenik
//
//  Created by Herb Bowie on 2/25/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MkdownLine {
    var line = ""
    var endsWithNewline = false
    var hashCount = 0
    var blankLine = true
    var repeatingChar: Character = " "
    var repeatCount = 0
    var onlyRepeating = false
    var textFound = false
    var text = ""
    
    var isEmpty: Bool {
        return line.count == 0 && !endsWithNewline
    }
    
}

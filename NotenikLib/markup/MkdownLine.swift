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
    var onlyRepeating = true
    var textFound = false
    var text = ""
    var indentLevels = 0
    
    var isEmpty: Bool {
        return line.count == 0 && !endsWithNewline
    }
    
    func display() {
        print(" ")
        print("MkdownLine.display")
        print("Input line: \(line)")
        print("Indent levels: \(indentLevels)")
        print("Blank Line? \(blankLine)")
        print("Is Empty? \(isEmpty)")
        print("Hash count: \(hashCount)")
        if repeatCount > 0 {
            print("Repeating char of \(repeatingChar), repeated \(repeatCount) times, only repeating chars? \(onlyRepeating)")
        }
        print("Text: '\(text)'")
    }
}

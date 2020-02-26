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
    var text: Substring?
    
    init() {
        
    }
    
    var isEmpty: Bool {
        return line.count == 0 && !endsWithNewline
    }
    
    func scanLine() {
        
        // Examine the beginning of the line
        var lineIndex = 0
        var start = line.startIndex

        while !textFound && start < line.endIndex {
            let char = line[start]
            if !char.isWhitespace {
                blankLine = false
            }
            if char == "#" && lineIndex == hashCount {
                hashCount += 1
            } else if ((char == "-" || char == "=")
                    && (repeatingChar == " " || repeatingChar == char)
                    && repeatCount == lineIndex) {
                repeatingChar = char
                repeatCount += 1
            } else {
                textFound = true
            }
            lineIndex += 1
            if !textFound {
                start = line.index(after: start)
            }
        }
        
        // Examine the end of the line
        var end = line.endIndex
        var endOfTextFound = false
        if hashCount > 0 {
            while end > start && !endOfTextFound {
                let next = line.index(before: end)
                let char = line[next]
                if char.isWhitespace || char == "#" {
                    end = next
                } else {
                    endOfTextFound = true
                }
            }
        }
        
        if !blankLine {
            text = line[start..<end]
        }
    }
}

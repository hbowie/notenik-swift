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

/// One line in Markdown syntax.
class MkdownLine {
    var line = ""
    var type: MkdownLineType = .blank
    var hashCount = 0
    var headingLevel = 0
    
    var repeatingChar: Character = " "
    var repeatCount = 0
    var onlyRepeating = true
    var onlyRepeatingAndSpaces = true
    
    var headingUnderlining: Bool {
        return (onlyRepeating && repeatCount >= 2 &&
            (repeatingChar == "=" || repeatingChar == "-"))
    }
    
    var horizontalRule: Bool {
        return onlyRepeatingAndSpaces && repeatCount >= 3 &&
            (repeatingChar == "-" || repeatingChar == "*" || repeatingChar == "_")
    }
    
    var textFound = false
    var text = ""
    
    var indentLevels = 0
    
    /// Return -1 if no table level, otherwise 0 or up. 
    var tableLevel: Int {
        if type.isListItem {
            return indentLevels
        } else {
            return indentLevels - 1
        }
    }
    var blockQuoteChars = 0 
    var trailingSpaceCount = 0
    var endsWithNewline = false
    var endsWithBackSlash = false
    
    var isEmpty: Bool {
        return line.count == 0 && !endsWithNewline
    }
    
    var endsWithLineBreak: Bool {
        return type != .blank && trailingSpaceCount >= 2
    }
    
    func display() {
        print(" ")
        print("MkdownLine.display")
        print("Input line: '\(line)'")
        if indentLevels > 0 {
            print("Indent levels: \(indentLevels)")
        }
        print("Line type: \(type)")
        if type == .heading {
            print("Heading level: \(headingLevel)")
        }
        if isEmpty {
            print("Is Empty? \(isEmpty)")
        }
        if blockQuoteChars > 0 {
            print("Block Quote Char count = \(blockQuoteChars)")
        }
        if hashCount > 0 {
            print("Hash count: \(hashCount)")
        }
        if repeatCount > 0 {
            print("Repeating char of \(repeatingChar), repeated \(repeatCount) times, only repeating chars? \(onlyRepeating)")
        }
        if headingUnderlining {
            print("Heading Underlining")
        }
        if trailingSpaceCount > 0 {
            print ("Trailing space count: \(trailingSpaceCount)")
        }
        if endsWithLineBreak {
            print("Ends with line break? \(endsWithLineBreak)")
        }
        if horizontalRule {
            print("Horizontal Rule")
        }
        if tableLevel >= 0 {
            print("Table level = \(tableLevel)")
        }
        print("Text: '\(text)'")
    }
}

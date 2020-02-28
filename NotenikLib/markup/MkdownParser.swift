//
//  MkdownParser.swift
//  Notenik
//
//  Created by Herb Bowie on 2/25/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MkdownParser {
    
    var mkdown:    String! = ""
    var nextIndex: String.Index
    var nextLine = MkdownLine()
    var lineIndex = -1
    var startLine: String.Index
    var startText: String.Index
    var endLine:   String.Index
    var endText:   String.Index
    var phase:     LinePhase = .indenting
    var spaceCount = 0
    var orderedListInProgress = false
    
    var lines: [MkdownLine] = []
    
    /// Initialize with an empty string.
    init() {
        nextIndex = mkdown.startIndex
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
    }
    
    /// Initialize with a string that will be copied.
    init(_ mkdown: String) {
        self.mkdown = mkdown
        nextIndex = self.mkdown.startIndex
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
    }
    
    /// Try to initialize by reading input from a URL.
    init?(_ url: URL) {
        do {
            try mkdown = String(contentsOf: url)
            nextIndex = mkdown.startIndex
            startText = nextIndex
            startLine = nextIndex
            endLine = nextIndex
            endText = nextIndex
        } catch {
            print("Error is \(error)")
            return nil
        }
    }
    
    /// Parse the Markdown source that has been provided.
    func parse() {
        
        nextIndex = mkdown.startIndex
        beginLine()
        
        while nextIndex < mkdown.endIndex {
             
            // Get the next character and adjust indices
            let char = mkdown[nextIndex]
            let lastIndex = nextIndex
            nextIndex = mkdown.index(after: nextIndex)
            lineIndex += 1
            
            // Deal with end of line
            if char.isNewline {
                nextLine.endsWithNewline = true
                finishLine()
                beginLine()
                continue
            }
            
            endLine = nextIndex
            
            // Check for a line of all dashes or all equal signs
            if (char == "-" || char == "=" || char == "*" || char == "_")
                && (nextLine.repeatingChar == " " || nextLine.repeatingChar == char) {
                nextLine.repeatingChar = char
                nextLine.repeatCount += 1
            } else if char == " " {
                nextLine.onlyRepeating = false
            } else {
                nextLine.onlyRepeatingAndSpaces = false
            }
            
            // Count indentaton levels
            if phase == .indenting {
                if char == "\t" {
                    nextLine.indentLevels += 1
                    continue
                } else if char.isWhitespace {
                    if spaceCount >= 3 {
                        nextLine.indentLevels += 1
                        spaceCount = 0
                    } else {
                        spaceCount += 1
                    }
                    continue
                } else {
                    phase = .leadingPunctuation
                }
            }
            
            nextLine.blankLine = false
            
            // Look for leading punctuation
            if phase == .leadingPunctuation {
                var plusOne: Character = "X"
                var plusTwo: Character = "X"
                if nextIndex < mkdown.endIndex {
                    plusOne = mkdown[nextIndex]
                    let plusTwoIndex = mkdown.index(after: nextIndex)
                    if plusTwoIndex < mkdown.endIndex {
                        plusTwo = mkdown[plusTwoIndex]
                    }
                }
                if char == ">" {
                    nextLine.blockQuoteChars += 1
                    continue
                }  else if char == "#" {
                    nextLine.hashCount += 1
                    continue
                } else if (char == "-" || char == "+" || char == "*") && plusOne == " " {
                    nextLine.unorderedItem = true
                    continue
                } else if char == "1" && plusOne == "." && plusTwo == " " {
                    nextLine.orderedItem = true
                    continue
                } else if char.isNumber && orderedListInProgress && plusOne == "." && plusTwo == " " {
                    nextLine.orderedItem = true
                    continue
                } else if char == "." && nextLine.orderedItem {
                    continue
                } else if char.isWhitespace {
                    continue
                } else {
                    phase = .text
                }
            }
            
            // Now look for text
            if phase == .text {
                if !nextLine.textFound {
                     nextLine.textFound = true
                     startText = lastIndex
                }
                if char == " " {
                    nextLine.trailingSpaceCount += 1
                } else {
                    nextLine.trailingSpaceCount = 0
                }
                if char == "\\" {
                    nextLine.endsWithBackSlash = true
                } else {
                    nextLine.endsWithBackSlash = false
                }
                if char == "#" && nextLine.hashCount > 0 {
                    // Drop trailing hash marks
                } else {
                    endText = nextIndex
                }
            }
            
        } // end of mkdown input
        finishLine()
    } // end of method parse
    
    func beginLine() {
        nextLine = MkdownLine()
        lineIndex = -1
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
        phase = .indenting
        spaceCount = 0
    }
    
    func finishLine() {
        if nextLine.endsWithBackSlash {
            endText = mkdown.index(before: endText)
            nextLine.trailingSpaceCount = 2
        }
        if endLine > startLine {
            nextLine.line = String(mkdown[startLine..<endLine])
        }
        if nextLine.headingUnderlining || nextLine.horizontalRule {
            nextLine.unorderedItem = false
        } else {
            if endText > startText {
                nextLine.text = String(mkdown[startText..<endText])
            }
        }
        guard !nextLine.isEmpty else { return }
        
        if nextLine.orderedItem {
            orderedListInProgress = true
        } else if !nextLine.blankLine {
            orderedListInProgress = false
        }
        
        nextLine.display()
        lines.append(nextLine)
    }
    
    enum LinePhase {
        case indenting
        case leadingPunctuation
        case text
    }
    
}

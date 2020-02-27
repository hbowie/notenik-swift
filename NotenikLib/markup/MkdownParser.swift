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
    var indenting = true
    var spaceCount = 0
    
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
                endLine = lastIndex
                finishLine()
                beginLine()
                continue
            }
            
            if !char.isWhitespace {
                nextLine.blankLine = false
            }
            
            if ((char == "-" || char == "=")
                && (nextLine.repeatingChar == " " || nextLine.repeatingChar == char)
                && nextLine.repeatCount == lineIndex) {
                nextLine.repeatingChar = char
                nextLine.repeatCount += 1
                continue
            } else {
                nextLine.onlyRepeating = false
            }
            
            if indenting {
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
                    indenting = false
                }
            }
                        
            if char == "#" && lineIndex == nextLine.hashCount {
                nextLine.hashCount += 1
                continue
            }
            
            if !char.isWhitespace {
                if !nextLine.textFound {
                    nextLine.textFound = true
                    startText = lastIndex
                }
            }
            
            if nextLine.hashCount > 0 && char == "#" {
                // do not advance the end index
            } else {
                endText = nextIndex
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
        indenting = true
        spaceCount = 0
    }
    
    func finishLine() {
        guard !nextLine.isEmpty else { return }
        if endLine > startLine {
            nextLine.line = String(mkdown[startLine..<endLine])
        }
        if endText > startText {
            nextLine.text = String(mkdown[startText..<endText])
        }
        nextLine.display()
        lines.append(nextLine)
    }
    
}

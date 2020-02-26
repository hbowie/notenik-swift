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
    
    var mkdown: String! = ""
    var nextIndex: String.Index
    var nextLine = MkdownLine()
    var lineIndex = 0
    var startText: String.Index
    
    var lines: [MkdownLine] = []
    
    /// Initialize with an empty string.
    init() {
        nextIndex = mkdown.startIndex
        startText = nextIndex
    }
    
    /// Initialize with a string that will be copied.
    init(_ mkdown: String) {
        self.mkdown = mkdown
        nextIndex = self.mkdown.startIndex
        startText = nextIndex
    }
    
    /// Try to initialize by reading input from a URL.
    init?(_ url: URL) {
        do {
            try mkdown = String(contentsOf: url)
            nextIndex = mkdown.startIndex
            startText = nextIndex
        } catch {
            return nil
        }
    }
    
    /// Parse the Markdown source that has been provided.
    func parse() {
        nextIndex = mkdown.startIndex
        startLine()
        while nextIndex < mkdown.endIndex {
             
            let char = mkdown[nextIndex]
            nextIndex = mkdown.index(after: nextIndex)
            if char.isNewline {
                nextLine.endsWithNewline = true
                endLine()
                startLine()
                continue
            }

            nextLine.line.append(char)


            while !textFound && start < originalLine.endIndex {
                let char = originalLine[start]
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
                    start = originalLine.index(after: start)
                }
            }
            
            // Examine the end of the line
            var end = originalLine.endIndex
            var endOfTextFound = false
            if hashCount > 0 {
                while end > start && !endOfTextFound {
                    let next = originalLine.index(before: end)
                    let char = originalLine[next]
                    if char.isWhitespace || char == "#" {
                        end = next
                    } else {
                        endOfTextFound = true
                    }
                }
            }
            
            if !blankLine {
                text = originalLine[start..<end]
            }
            
            
        } // end of mkdown input
        endLine()
    } // end of method parse
    
    func startLine() {
        nextLine = MkdownLine()
        lineIndex = 0
        startText = nextIndex
    }
    
    func endLine() {
        guard !nextLine.isEmpty else { return }
        lines.append(nextLine)
    }
    
}

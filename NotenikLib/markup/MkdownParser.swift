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
    var lastLine = MkdownLine()
    
    var lineIndex = -1
    var startLine: String.Index
    var startText: String.Index
    var endLine:   String.Index
    var endText:   String.Index
    var phase:     LinePhase = .indenting
    var spaceCount = 0
    var orderedListInProgress = false
    
    var linkLabelPhase: LinkLabelDefPhase = .na
    var angleBracketsUsed = false
    var titleEndChar: Character = " "
    
    var refLink = RefLink()
    
    var linkDict: [String:RefLink] = [:]
    
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
            
            if nextLine.type == .blank {
                nextLine.type = .ordinaryText
            }
            
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
                    nextLine.type = .unorderedItem
                    continue
                } else if char == "1" && plusOne == "." && plusTwo == " " {
                    nextLine.type = .orderedItem
                    continue
                } else if char.isNumber && orderedListInProgress && plusOne == "." && plusTwo == " " {
                    nextLine.type = .orderedItem
                    continue
                } else if char == "." && nextLine.type == .orderedItem {
                    continue
                } else if char == "[" && nextLine.indentLevels < 1 {
                    print("Left Bracket found")
                    linkLabelPhase = .leftBracket
                    refLink = RefLink()
                    phase = .text
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
                
                // Let's see if we have a possible reference link definition in work.
                if linkLabelPhase != .na {
                    linkLabelExamineChar(char)
                }
            }
            
        } // end of mkdown input
        finishLine()
        for line in lines {
            line.display()
        }
        
        for (_, link) in linkDict {
            link.display()
        }
    } // end of method parse
    
    func linkLabelExamineChar(_ char: Character) {
        
        print("linkLabelExamineChar char = \(char)")
        switch linkLabelPhase {
        case .na:
            break
        case .leftBracket:
            if char == "[" && refLink.label.count == 0 {
                break
            } else if char == "]" {
                linkLabelPhase = .rightBracket
            } else {
                refLink.label.append(char.lowercased())
            }
        case .rightBracket:
            if char == ":" {
                linkLabelPhase = .colon
            } else {
                linkLabelPhase = .na
            }
        case .colon:
            if !char.isWhitespace {
                if char == "<" {
                    angleBracketsUsed = true
                    linkLabelPhase = .linkStart
                } else {
                    refLink.link.append(char)
                    linkLabelPhase = .linkStart
                }
            }
        case .linkStart:
            if angleBracketsUsed {
                if char == ">" {
                    linkLabelPhase = .linkEnd
                } else {
                    refLink.link.append(char)
                }
            } else if char.isWhitespace {
                linkLabelPhase = .linkEnd
            } else {
                refLink.link.append(char)
            }
        case .linkEnd:
            if char == "\"" || char == "'" || char == "(" {
                print("Link End")
                linkLabelPhase = .titleStart
                if char == "(" {
                    titleEndChar = ")"
                } else {
                    titleEndChar = char
                }
                print("  - Setting title start char to \(titleEndChar)")
            } else if !char.isWhitespace {
                linkLabelPhase = .na
            }
        case .titleStart:
            if char == titleEndChar {
                linkLabelPhase = .titleEnd
            } else {
                refLink.title.append(char)
            }
        case .titleEnd:
            if !char.isWhitespace {
                linkLabelPhase = .na
            }
        }
    }
    
    func beginLine() {
        nextLine = MkdownLine()
        lineIndex = -1
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
        phase = .indenting
        spaceCount = 0
        if linkLabelPhase != .linkEnd {
            linkLabelPhase = .na
            angleBracketsUsed = false
            refLink = RefLink()
        }
        titleEndChar = " "
    }
    
    func finishLine() {
        
        if endLine > startLine {
            nextLine.line = String(mkdown[startLine..<endLine])
        }
        
        if refLink.isValid && (linkLabelPhase == .linkEnd || linkLabelPhase == .linkStart) {
            linkDict[refLink.label] = refLink
            nextLine.type = .linkDef
            linkLabelPhase = .linkEnd
        } else if refLink.isValid && linkLabelPhase == .titleEnd {
            let def = linkDict[refLink.label]
            if def == nil {
                linkDict[refLink.label] = refLink
                nextLine.type = .linkDef
            } else {
                nextLine.type = .linkDefExt
            }
        } else if nextLine.headingUnderlining && nextLine.horizontalRule {
            if lastLine.type == .blank {
                nextLine.type = .horizontalRule
            } else if nextLine.repeatCount > 4 {
                nextLine.type = .h2Underlines
            } else {
                nextLine.type = .horizontalRule
            }
        } else if nextLine.headingUnderlining {
            if nextLine.repeatingChar == "=" {
                nextLine.type = .h1Underlines
            } else {
                nextLine.type = .h2Underlines
            }
        } else if nextLine.horizontalRule {
            nextLine.type = .horizontalRule
        } else if nextLine.hashCount >= 1 && nextLine.hashCount <= 6 {
            nextLine.type = .heading
            nextLine.headingLevel = nextLine.hashCount
        }
        
        if nextLine.endsWithBackSlash {
            endText = mkdown.index(before: endText)
            nextLine.trailingSpaceCount = 2
        }

        if nextLine.type.hasText && endText > startText {
            nextLine.text = String(mkdown[startText..<endText])
        }
        
        guard !nextLine.isEmpty else { return }
        
        if nextLine.type == .orderedItem {
            orderedListInProgress = true
        } else if nextLine.type != .blank {
            orderedListInProgress = false
        }
        
        if nextLine.type == .h1Underlines {
            lastLine.type = .heading
            lastLine.headingLevel = 1
        } else if nextLine.type == .h2Underlines {
            lastLine.type = .heading
            lastLine.headingLevel = 2
        }
        
        lines.append(nextLine)
        lastLine = nextLine
    }
    
    enum LinePhase {
        case indenting
        case leadingPunctuation
        case text
    }
    
    enum LinkLabelDefPhase {
        case na
        case leftBracket
        case rightBracket
        case colon
        case linkStart
        case linkEnd
        case titleStart
        case titleEnd
    }
    
    class RefLink {
        var label = ""
        var link  = ""
        var title = ""
        
        var isValid: Bool {
            return label.count > 0 && link.count > 0
        }
        
        func display() {
            print(" ")
            print("Reference Link Definition")
            print("Label: \(label)")
            print("Link:  \(link)")
            print("Title: \(title)")
        }
    }
    
}

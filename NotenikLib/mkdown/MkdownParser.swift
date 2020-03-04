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

/// A class to parse Mardkown input and do useful things with it.
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
    var listsInProgress: [ListInfo] = []
    var currentTableLevel: Int {
        return listsInProgress.count - 1
    }
    
    var linkLabelPhase: LinkLabelDefPhase = .na
    var angleBracketsUsed = false
    var titleEndChar: Character = " "
    
    var refLink = RefLink()
    
    var linkDict: [String:RefLink] = [:]
    
    var lines: [MkdownLine] = []
    
    var openBlock = ""
    
    var nextChunk = MkdownChunk()
    var chunks: [MkdownChunk] = []
    
    var writer = Markedup()
    
    var html: String { return writer.code }
    
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
    
    func parse() {
        firstPass()
        secondPass()
    }
    
    /// Make our first pass through the Markdown, identifying basic info about each line.
    func firstPass() {
        
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
            
            // Count indentation levels
            if phase == .indenting {
                if char == "\t" {
                    nextLine.indentLevels += 1
                } else if char.isWhitespace {
                    if spaceCount >= 3 {
                        nextLine.indentLevels += 1
                        spaceCount = 0
                    } else {
                        spaceCount += 1
                    }
                } else {
                    phase = .leadingPunctuation
                }
            }
            
            // See if the indention level makes this a code line.
            if (phase == .indenting
                && nextLine.indentLevels > 0
                && nextLine.type != .code
                && nextLine.indentLevels > (currentTableLevel + 1)
                && linkLabelPhase != .linkEnd) {
                nextLine.type = .code
                startText = nextIndex
                phase = .text
            }
            
            // If we're still indenting, then we're done with this character.
            if phase == .indenting {
                continue
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
    } // end of method parse
    
    var orderedListInProgress: Bool {
        print("Ordered list in progress?")
        print("Next Line Table level: \(nextLine.tableLevel) ")
        print("Current table level: \(currentTableLevel)")
        if nextLine.tableLevel > currentTableLevel {
            return false
        } else if currentTableLevel < 0 {
            return false
        } else if nextLine.tableLevel < 0 {
            return false
        } else {
            let listInfo = listsInProgress[nextLine.tableLevel]
            return (listInfo.type == .ordered)
        }
    }
    
    func linkLabelExamineChar(_ char: Character) {
        
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
                linkLabelPhase = .titleStart
                if char == "(" {
                    titleEndChar = ")"
                } else {
                    titleEndChar = char
                }
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
    
    // Prepare for a new Markdown line.
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
    
    /// Wrap up initial examination of the line and figure out what to do with it.
    func finishLine() {
        
        // Capture the entire line for later processing.
        if endLine > startLine {
            nextLine.line = String(mkdown[startLine..<endLine])
        }
        
        // Figure out some of the less ordinary line types.
        if nextLine.type == .code {
            // Don't bother looking for other indicators
        } else if refLink.isValid && (linkLabelPhase == .linkEnd || linkLabelPhase == .linkStart) {
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
        
        // If the line ends with a backslash, treat this like a line break.
        if nextLine.type != .code && nextLine.endsWithBackSlash {
            endText = mkdown.index(before: endText)
            nextLine.trailingSpaceCount = 2
        }

        // Capture the text portion of the line, if it has any.
        if nextLine.type.hasText && endText > startText {
            nextLine.text = String(mkdown[startText..<endText])
        }
        
        // If the line has no content and no end of line character(s), then ignore it.
        guard !nextLine.isEmpty else { return }
        
        // Let's see where we're at in any lists.
        if nextLine.type.isListItem {
            while currentTableLevel > nextLine.tableLevel {
                listsInProgress.removeLast()
            }
            if nextLine.tableLevel == currentTableLevel {
                let listInfo = listsInProgress[currentTableLevel]
                if nextLine.type == .orderedItem && listInfo.type == .ordered {
                    listInfo.itemNumber += 1
                } else if nextLine.type == .unorderedItem && listInfo.type == .unordered {
                    // OK as-is
                } else if nextLine.type == .orderedItem {
                    listInfo.type = .ordered
                    listInfo.itemNumber = 1
                } else {
                    listInfo.type = .unordered
                }
            } else {
                let listInfo = ListInfo()
                listInfo.setTypeFrom(lineType: nextLine.type)
                listInfo.itemNumber = 1
                listsInProgress.append(listInfo)
            }
        } else if nextLine.type == .blank {
            // Leave status as-is
        } else if nextLine.indentLevels > 0 {
            if nextLine.tableLevel > currentTableLevel {
                nextLine.type = .code
            }
        } else {
            while currentTableLevel >= 0 {
                listsInProgress.removeLast()
            }
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
    
    func secondPass() {
        writer = Markedup()
        for line in lines {
            switch line.type {
            case .blank:
                endBlock()
            case .heading:
                endBlock()
                writer.startHeading(level: line.headingLevel)
                chunkAndWrite(line)
                writer.finishHeading(level: line.headingLevel)
            case .ordinaryText:
                if openBlock == "" {
                    writer.startParagraph()
                    openBlock = "p"
                }
                textToChunks(line)
            default:
                break
            }
        }
        endBlock()
    }
    
    func startBlock(_ element: String) {
        openBlock = element
        chunks = []
    }
    
    func endBlock() {
        writeChunks()
        switch openBlock {
        case "":
            break
        case "p":
            writer.finishParagraph()
        default:
            break
        }
        openBlock = ""
    }
    
    func chunkAndWrite(_ line: MkdownLine) {
        textToChunks(line)
        writeChunks()
    }
    
    func textToChunks(_ line: MkdownLine) {
        
        nextChunk = MkdownChunk()
        for char in line.text {
            switch char {
            case "*":
                finishNextChunk()
                nextChunk.text = "*"
                nextChunk.type = .asterisk
            case "_":
                finishNextChunk()
                nextChunk.text = "_"
                nextChunk.type = .underline
            case " ":
                if nextChunk.text.count == 0 {
                    nextChunk.startsWithSpace = true
                }
                nextChunk.endsWithSpace = true
                nextChunk.text.append(char)
            default:
                nextChunk.text.append(char)
            }
            if !char.isWhitespace {
                nextChunk.endsWithSpace = false
            }
        }
        finishNextChunk()
        
        if line.endsWithLineBreak {
            writeChunks()
            writer.lineBreak()
        }
    }
    
    func finishNextChunk() {
        if nextChunk.text.count > 0 {
            chunks.append(nextChunk)
        }
        nextChunk = MkdownChunk()
    }
    
    func writeChunks() {
        
        // Let's try to match up any unmatched enclosures
        var index = 0
        var indexPlus = 1
        for chunk in chunks {
            var nextChunk = MkdownChunk()
            if indexPlus < chunks.count {
                nextChunk = chunks[indexPlus]
            }
            switch chunk.type {
            case .asterisk, .underline:
                if chunk.text == nextChunk.text {
                    let pairFound = scanForMatchingPair(from: index + 3, chunk: chunk)
                }
            default:
                break
            }
            index = indexPlus
            indexPlus += 1
        }
        
        for chunk in chunks {
            switch chunk.type {
            default:
                writer.append(chunk.text)
            }
        }
        chunks = []
    }
    
    func scanForMatchingPair(from: Int, chunk: MkdownChunk) -> Bool {
        var found = false
        var index = from
        var indexPlus = index + 1
        while !found && indexPlus < chunks.count {
            
        }
        return found
    }
    
    enum LinePhase {
        case indenting
        case leadingPunctuation
        case text
    }
    
    enum ListType {
        case ordered
        case unordered
    }
    
    class ListInfo {
        var type: ListType = .unordered
        var itemNumber = 0
        
        func setTypeFrom(lineType: MkdownLineType) {
            switch lineType {
            case .orderedItem:
                type = .ordered
            case .unorderedItem:
                type = .unordered
            default:
                break
            }
        }
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

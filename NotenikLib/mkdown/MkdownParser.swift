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
    
    // ===============================================================
    //
    // OVERALL PARSING STRATEGY
    //
    // Initialization: Capture the Markdown text to be parsed.
    //
    // Section 1: Parse the text and break it into lines, identifying
    //            the type of each line, along with other metadata.
    //
    // Section 2: Go through the lines, generating HTML output. 
    // ===============================================================
    
    var mkdown:    String! = ""
    var nextIndex: String.Index
    
    var nextLine = MkdownLine()
    var lastLine = MkdownLine()
    var lastNonBlankLine = MkdownLine()
    
    var lineIndex = -1
    var startLine: String.Index
    var startText: String.Index
    var endLine:   String.Index
    var endText:   String.Index
    var phase:     MkdownLinePhase = .leadingPunctuation
    var spaceCount = 0
    
    var leadingNumber = false
    var leadingNumberAndPeriod = false
    var leadingNumberPeriodAndSpace = false
    
    var leadingBullet = false
    
    var leadingLeftAngleBracket = false
    var leadingLeftAngleBracketAndSlash = false
    var possibleTagPending = false
    var possibleTag = ""
    var goodTag = false
    
    var openHTMLblockTag = ""
    var openHTMLblock = false
    
    var startNumber: String.Index
    var startBullet: String.Index
    
    var linkLabelPhase: LinkLabelDefPhase = .na
    var angleBracketsUsed = false
    var titleEndChar: Character = " "
    
    var refLink = RefLink()
    
    /// Initialize with an empty string.
    init() {
        nextIndex = mkdown.startIndex
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
        startNumber = nextIndex
        startBullet = nextIndex
    }
    
    /// Initialize with a string that will be copied.
    init(_ mkdown: String) {
        self.mkdown = mkdown
        nextIndex = self.mkdown.startIndex
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
        startNumber = nextIndex
        startBullet = nextIndex
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
            startNumber = nextIndex
            startBullet = nextIndex
        } catch {
            print("Error is \(error)")
            return nil
        }
    }
    
    func parse() {
        mdToLines()
        linesOut()
    }
    
    // ===========================================================
    //
    // Section 1 - Parse the input block of Markdown text, and
    // break down into lines.
    //
    // ===========================================================
    
    /// Make our first pass through the Markdown, identifying basic info about each line.
    func mdToLines() {
        
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
            } else if char == ">" && phase == .leadingPunctuation {
                // Blockquotes make no difference
            } else {
                nextLine.onlyRepeatingAndSpaces = false
            }
            
            // Check for an HTML block
            if lineIndex == 0 && char == "<" {
                leadingLeftAngleBracket = true
                possibleTagPending = true
            } else if possibleTagPending {
                if char.isWhitespace || char == ">" {
                    possibleTagPending = false
                    switch possibleTag {
                    case "h1", "h2", "h3", "h4", "h5", "h6":
                        goodTag = true
                    case "div", "pre", "p", "table":
                        goodTag = true
                    case "ol", "ul", "dl", "dt", "li":
                        goodTag = true
                    case "hr", "blockquote", "address":
                        goodTag = true
                    default:
                        goodTag = false
                    }
                } else if lineIndex == 1 && char == "/" {
                    leadingLeftAngleBracketAndSlash = true
                } else {
                    possibleTag.append(char)
                }
            } 
            
            // Check the beginning of the line for significant characters.
            if phase == .leadingPunctuation {
                if openHTMLblock {
                    phase = .text
                    nextLine.makeHTML()
                } else if leadingNumberPeriodAndSpace {
                    if char.isWhitespace {
                        continue
                    } else {
                        phase = .text
                    }
                } else if leadingNumberAndPeriod {
                    if char.isWhitespace {
                        nextLine.makeOrdered(previousLine: lastLine,
                                             previousNonBlankLine: lastNonBlankLine)
                        leadingNumberPeriodAndSpace = true
                        continue
                    } else {
                        phase = .text
                        nextLine.textFound = true
                        startText = startNumber
                    }
                } else if leadingNumber {
                    if char.isNumber {
                        continue
                    } else if char == "." {
                        leadingNumberAndPeriod = true
                        continue
                    } else {
                        phase = .text
                        nextLine.textFound = true
                        startText = startNumber
                    }
                } else if nextLine.leadingBulletAndSpace {
                    if char.isWhitespace {
                        continue
                    } else {
                        phase = .text
                    }
                } else if leadingBullet {
                    if char.isWhitespace {
                        nextLine.leadingBulletAndSpace = true
                    } else {
                        phase = .text
                        nextLine.textFound = true
                        startText = startBullet
                    }
                } else if char == " " && spaceCount < 3 {
                    spaceCount += 1
                    continue
                } else {
                    spaceCount = 0
                    if char == "\t" || char == " " {
                        nextLine.indentLevels += 1
                        let continuedBlock = nextLine.continueBlock(from: lastLine, forLevel: nextLine.indentLevels)
                            // nextLine.indentLevels > 0
                            // nextLine.type != .code
                            // nextLine.indentLevels > currentListLevel
                            // linkLabelPhase != .linkEnd)
                        if continuedBlock {
                            continue
                        } else if nextLine.type != .code {
                            nextLine.type = .code
                            startText = nextIndex
                            phase = .text
                            nextLine.textFound = true
                        }
                    } else if char == ">" {
                        nextLine.blocks.append("blockquote")
                        continue
                    } else if char == "#" {
                        _ = nextLine.incrementHeadingLevel()
                        continue
                    } else if char == "-" || char == "+" || char == "*" {
                        leadingBullet = true
                        startBullet = lastIndex
                        continue
                    } else if char.isNumber {
                        leadingNumber = true
                        startNumber = lastIndex
                        continue
                    } else if char == "[" && nextLine.indentLevels < 1 {
                        linkLabelPhase = .leftBracket
                        refLink = RefLink()
                        phase = .text
                    } else {
                        phase = .text
                    }
                }
            }
            
            if nextLine.type == .blank {
                nextLine.type = .ordinaryText
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
                if char == "#" && nextLine.hashCount > 0 && nextLine.hashCount < 7 {
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
    } // end of func
    
    /// Prepare for a new Markdown line.
    func beginLine() {
        nextLine = MkdownLine()
        lineIndex = -1
        startText = nextIndex
        startLine = nextIndex
        endLine = nextIndex
        endText = nextIndex
        phase = .leadingPunctuation
        spaceCount = 0
        if linkLabelPhase != .linkEnd {
            linkLabelPhase = .na
            angleBracketsUsed = false
            refLink = RefLink()
        }
        titleEndChar = " "
        leadingNumber = false
        leadingNumberAndPeriod = false
        leadingNumberPeriodAndSpace = false
        leadingBullet = false
        startNumber = nextIndex
        startBullet = nextIndex
        leadingLeftAngleBracket = false
        leadingLeftAngleBracketAndSlash = false
        possibleTag = ""
        possibleTagPending = false
        goodTag = false
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
        } else if (refLink.isValid
            && (linkLabelPhase == .linkEnd || linkLabelPhase == .linkStart)) {
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
                nextLine.makeHorizontalRule()
            } else if nextLine.repeatCount > 4 {
                nextLine.type = .h2Underlines
            } else {
                nextLine.makeHorizontalRule()
            }
        } else if nextLine.headingUnderlining {
            if nextLine.repeatingChar == "=" {
                nextLine.type = .h1Underlines
            } else {
                nextLine.type = .h2Underlines
            }
        } else if nextLine.horizontalRule {
            nextLine.makeHorizontalRule()
        } else if nextLine.hashCount >= 1 && nextLine.hashCount <= 6 {
            nextLine.type = .heading
            nextLine.headingLevel = nextLine.hashCount
        } else if nextLine.hashCount > 0 {
            startText = startLine
            nextLine.makeOrdinary()
        } else if nextLine.leadingBulletAndSpace {
            nextLine.makeUnordered(previousLine: lastLine,
                                   previousNonBlankLine: lastNonBlankLine)
        }
        
        // Check for lines of HTML
        if openHTMLblock {
            if nextLine.type == .blank {
                openHTMLblock = false
            } else {
                nextLine.makeHTML()
                if (leadingLeftAngleBracketAndSlash
                    && goodTag
                    && possibleTag == openHTMLblockTag) {
                    openHTMLblock = false
                }
            }
        } else if (lastLine.type == .blank
            && leadingLeftAngleBracket
            && !leadingLeftAngleBracketAndSlash
            && goodTag) {
            nextLine.makeHTML()
            if possibleTag != "hr" {
                openHTMLblockTag = possibleTag
                openHTMLblock = true
            }
        }
        if nextLine.type == .html {
            startText = startLine
        }
        
        if nextLine.type == .h1Underlines {
            lastLine.heading1()
        } else if nextLine.type == .h2Underlines {
            lastLine.heading2()
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
        nextLine.setListInfo()
        if nextLine.type.isListItem {
            while currentListLevel > nextLine.listLevel {
                listsInProgress.removeLast()
            }
            if nextLine.listLevel == currentListLevel {
                if nextLine.type == .orderedItem && currentList.type == .ordered {
                    currentList.number += 1
                } else if nextLine.type == .unorderedItem && currentList.type == .unordered {
                    // OK as-is
                } else if nextLine.type == .orderedItem {
                    currentList.type = .ordered
                    currentList.number = 1
                } else {
                    currentList.type = .unordered
                }
            } else {
                let listInfo = MkdownListInfo()
                listInfo.setTypeFrom(lineType: nextLine.type)
                listInfo.number = 1
                listsInProgress.append(listInfo)
            }
        } else if nextLine.type == .blank {
            // Leave status as-is
        } else if nextLine.indentLevels > 0 {
            if nextLine.listLevel > currentListLevel {
                nextLine.type = .code
            }
        } else {
            while currentListLevel >= 1 {
                listsInProgress.removeLast()
            }
        }
        
        if nextLine.type == .h1Underlines {
            lastLine.heading1()
        } else if nextLine.type == .h2Underlines {
            lastLine.heading2()
        }
        
        if lastLine.quoteLevel > 0 && nextLine.type == .ordinaryText && nextLine.quoteLevel == 0 {
            nextLine.quoteLevel = lastLine.quoteLevel
        }
        
        if nextLine.type == .ordinaryText {
            nextLine.carryBlockquotesForward(lastLine: lastLine)
            nextLine.addParagraph()
        }
        
        lines.append(nextLine)
        lastLine = nextLine
        if nextLine.type != .blank {
            lastNonBlankLine = nextLine
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
    
    // ===========================================================
    //
    // This is the data shared between Section 1 and Section 2.
    //
    // ===========================================================
    
    var linkDict: [String:RefLink] = [:]
    var lines:    [MkdownLine] = []
    
    var listsInProgress: [MkdownListInfo] = [MkdownListInfo()]
    
    var currentListLevel: Int {
        return listsInProgress.count - 1
    }
    
    var currentList: MkdownListInfo {
        return listsInProgress[currentListLevel]
    }
    
    func orderedListInProgress (forLevel: Int) -> Bool {
        if forLevel != currentListLevel {
            return false
        } else if currentListLevel < 1 {
            return false
        } else if forLevel < 1 {
            return false
        } else {
            return (currentList.type == .ordered)
        }
    }

    // ===========================================================
    //
    // Section 2 - Take the lines and convert them to HTML output.
    //
    // ===========================================================
    
    var writer = Markedup()
    
    var html: String { return writer.code }
    
    var lastQuoteLevel = 0
    var openBlock = ""
    
    var nextChunk = MkdownChunk()
    var chunks: [MkdownChunk] = []
    
    var startChunk = MkdownChunk()
    var consecutiveStartCount = 0
    var consecutiveCloseCount = 0
    var leftToClose = 0
    var startIndex = -1
    var matchStart = -1
    
    var openBlocks = MkdownBlockStack()
    
    /// Now that we have the input divided into lines, and the lines assigned types,
    /// let's generate the output HTML.
    func linesOut() {
        
        writer = Markedup()
        lastQuoteLevel = 0
        listsInProgress = [MkdownListInfo()]
        openBlocks = MkdownBlockStack()
        
        for line in lines {
            line.display()
            // Close any outstanding blocks that are no longer in effect.
            var startToClose = 0
            while startToClose < openBlocks.count {
                guard startToClose < line.blocks.count else { break }
                if openBlocks.blocks[startToClose] != line.blocks.blocks[startToClose] {
                    break
                }
                startToClose += 1
            }
            
            closeBlocks(from: startToClose)
            
            // Now start any new business.
            
            var blockToOpen = openBlocks.count
            while blockToOpen < line.blocks.count {
                let tag = line.blocks.blocks[blockToOpen].tag
                openBlock(tag)
                openBlocks.append(tag)
                blockToOpen += 1
            }
            
            switch line.type {
            case .heading:
                chunkAndWrite(line)
            case .horizontalRule:
                writer.horizontalRule()
            case .html:
                writer.writeLine(line.line)
            case .ordinaryText:
                textToChunks(line)
            case .orderedItem, .unorderedItem:
                textToChunks(line)
            default:
                break
            }
        }
        closeBlocks(from: 0)
    }
    
    func openBlock(_ tag: String) {
        switch tag {
        case "blockquote":
            writer.startBlockQuote()
        case "code":
            writer.startCode()
        case "h1":
            writer.startHeading(level: 1)
        case "h2":
            writer.startHeading(level: 2)
        case "h3":
            writer.startHeading(level: 3)
        case "h4":
            writer.startHeading(level: 4)
        case "h5":
            writer.startHeading(level: 5)
        case "h6":
            writer.startHeading(level: 6)
        case "li":
            writer.startListItem()
        case "ol":
            writer.startOrderedList(klass: nil)
        case "p":
            writer.startParagraph()
        case "pre":
            writer.startPreformatted()
        case "ul":
            writer.startUnorderedList(klass: nil)
        default:
            print("Don't know how to open tag of \(tag)")
        }
        chunks = []
    }
    
    func closeBlocks(from startToClose: Int) {
        var blockToClose = openBlocks.count - 1
        while blockToClose >= startToClose {
            closeBlock(openBlocks.blocks[blockToClose].tag)
            openBlocks.removeLast()
            blockToClose -= 1
        }
    }
    
    func closeBlock(_ tag: String) {
        writeChunks()
        switch tag {
        case "blockquote":
            writer.finishBlockQuote()
        case "code":
            writer.finishCode()
        case "h1":
            writer.finishHeading(level: 1)
        case "h2":
            writer.finishHeading(level: 2)
        case "h3":
            writer.finishHeading(level: 3)
        case "h4":
            writer.finishHeading(level: 4)
        case "h5":
            writer.finishHeading(level: 5)
        case "h6":
            writer.finishHeading(level: 6)
        case "li":
            writer.finishListItem()
        case "ol":
            writer.finishOrderedList()
        case "p":
            writer.finishParagraph()
        case "pre":
            writer.finishPreformatted()
        case "ul":
            writer.finishUnorderedList()
        default:
            print("Don't know how to close tag of \(tag)")
        }
    }
    
    /// Divide a line up into chunks, then write them out.
    func chunkAndWrite(_ line: MkdownLine) {
        textToChunks(line)
        writeChunks()
    }
    
    /// Divide another line of Markdown into chunks.
    func textToChunks(_ line: MkdownLine) {
        
        nextChunk = MkdownChunk()
        var backslashed = false
        var lastChar: Character = " "
        for char in line.text {
            if backslashed {
                addCharAsChunk(char: char, type: .literal, lastChar: lastChar)
                backslashed = false
            } else if char == "\\" {
                addCharAsChunk(char: char, type: .backSlash, lastChar: lastChar)
                backslashed = true
            } else if char == "*" {
                addCharAsChunk(char: char, type: .asterisk, lastChar: lastChar)
            } else if char == "_" {
                addCharAsChunk(char: char, type: .underline, lastChar: lastChar)
            } else if char == " " {
                if nextChunk.text.count == 0 {
                    nextChunk.startsWithSpace = true
                }
                nextChunk.endsWithSpace = true
                nextChunk.text.append(char)
            } else {
                nextChunk.text.append(char)
            }
            if !char.isWhitespace {
                nextChunk.endsWithSpace = false
            }
            lastChar = char
        }
        finishNextChunk()
        
        if line.endsWithLineBreak {
            writeChunks()
            writer.lineBreak()
        }
    }
    
    /// Add a character as its own chunk.
    func addCharAsChunk(char: Character, type: MkdownChunkType, lastChar: Character) {
        if nextChunk.text.count > 0 {
            finishNextChunk()
        }
        nextChunk.setTextFrom(char: char)
        nextChunk.type = type
        nextChunk.spaceBefore = lastChar.isWhitespace
        addChunk(nextChunk)
        nextChunk = MkdownChunk()
    }
    
    /// Add the chunk to the array.
    func finishNextChunk() {
        if nextChunk.text.count > 0 {
            addChunk(nextChunk)
        }
        nextChunk = MkdownChunk()
    }
    
    func addChunk(_ chunk: MkdownChunk) {
        if chunks.count > 0 {
            let last = chunks.count - 1
            chunks[last].spaceAfter = chunk.startsWithSpace
        }
        chunks.append(chunk)
    }
    
    /// Now finish evaluation of the chunks and write them out.
    func writeChunks() {
        
        // Let's try to match up any unmatched enclosures
        var index = 0
        while index < chunks.count {
            let chunk = chunks[index]
            switch chunk.type {
            case .asterisk, .underline:
                scanForClosure(forChunkAt: index)
            default:
                break
            }
            index += 1
        }
        
        for chunk in chunks {
            write(chunk: chunk)
        }
        chunks = []
    }
    
    /// If we have an asterisk or an underline, look for the closing symbols to end the emphasis span.
    func scanForClosure(forChunkAt: Int) {
        // print(" ")
        // print("Scan for Closure")
        startIndex = forChunkAt
        startChunk = chunks[startIndex]
        // startChunk.display(title: "Starting Chunk", indenting: 0)
        var next = startIndex + 1
        consecutiveStartCount = 1
        leftToClose = 1
        consecutiveCloseCount = 0
        matchStart = -1
        while leftToClose > 0 && next < chunks.count {
            let nextChunk = chunks[next]
            // nextChunk.display(title: "Next Chunk", indenting: 4)
            if nextChunk.type == startChunk.type && next == (startIndex + consecutiveStartCount) {
                consecutiveStartCount += 1
                leftToClose += 1
            } else if nextChunk.type == startChunk.type {
                if consecutiveCloseCount == 0 {
                    matchStart = next
                    consecutiveCloseCount = 1
                } else if next == (matchStart + consecutiveCloseCount) {
                    consecutiveCloseCount += 1
                }
            } else if consecutiveCloseCount > 0 {
                processClosure()
            }
            next += 1
        }
        processClosure()
    }
    
    /// Let's close things up.
    func processClosure() {
        guard consecutiveCloseCount > 0 else { return }
        if consecutiveStartCount == consecutiveCloseCount {
            switch consecutiveStartCount {
            case 1:
                startChunk.type = .startEmphasis
                chunks[matchStart].type = .endEmphasis
                consecutiveCloseCount = 0
            case 2:
                startChunk.type = .startStrong1
                chunks[startIndex + 1].type = .startStrong2
                chunks[matchStart].type = .endStrong1
                chunks[matchStart + 1].type = .endStrong2
                consecutiveCloseCount = 0
            case 3:
                startChunk.type = .startStrong1
                chunks[startIndex + 1].type = .startStrong2
                chunks[startIndex + 2].type = .startEmphasis
                chunks[matchStart].type = .endEmphasis
                chunks[matchStart + 1].type = .endStrong1
                chunks[matchStart + 2].type = .endStrong2
                consecutiveCloseCount = 0
            default:
                break
            }
            leftToClose = 0
        } else if consecutiveStartCount == 3 {
            if consecutiveCloseCount == 1 {
                chunks[startIndex + 2].type = .startEmphasis
                chunks[matchStart].type = .endEmphasis
                leftToClose = 2
                consecutiveStartCount = 2
                consecutiveCloseCount = 0
            } else if consecutiveCloseCount == 2 {
                chunks[startIndex + 1].type = .startStrong1
                chunks[startIndex + 2].type = .startStrong2
                chunks[matchStart].type = .endStrong1
                chunks[matchStart + 1].type = .endStrong2
                leftToClose = 1
                consecutiveStartCount = 1
                consecutiveCloseCount = 0
            }
        }
    }
    
    func write(chunk: MkdownChunk) {
        switch chunk.type {
        case .backSlash:
            break
        case .literal:
            writer.append(chunk.text)
        case .startEmphasis:
            writer.startEmphasis()
        case .endEmphasis:
            writer.finishEmphasis()
        case .startStrong1:
            writer.startStrong()
        case .startStrong2:
            break
        case .endStrong1:
            writer.finishStrong()
        case .endStrong2:
            break
        default:
            writer.append(chunk.text)
        }
    }
    
}

//
//  TextileLine.swift
//  Notenik
//
//  Created by Herb Bowie on 10/3/19.
//
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One line of Textile, containing zero or more chunks
class TextileLine {
    
    /// The block of which this line is a part.
    var block = TextileBlock()
    
    var line = ""
    
    var startOfInfo: String.Index!
    var startOfChunks: String.Index!
    
    /// The chunks that make up this line.
    var chunks: [TextileChunk] = []
    
    /// An indicator of the type of line this is.
    var type:   TextileLineType = .ordinary
    
    /// The current chunk we're building.
    var chunk = TextileChunk()
    
    /// Characters whose disposition is as yet undecided.
    var pendingChars = ""
    
    var openingLink: TextileChunk? = nil
    
    /// Initialize with the block of which this line is a part.
    init(line: String) {
        self.line = line
        self.startOfInfo = line.startIndex
        self.startOfChunks = line.startIndex
    }
    
    /// Set the text for the line, and break it down into chunks.
    func scanForLineType() {
        type = .blank
        chunks = []
        var index = line.startIndex
        for char in line {
            if char == "*" {
                type = .unordered
            } else if char == "#" {
                type = .ordered
            } else if char == "<" {
                type = .html
            } else if !char.isWhitespace {
                if type == .blank {
                    type = .ordinary
                    break
                } else {
                    startOfInfo = index
                    startOfChunks = index
                    break
                }
            }
            index = line.index(after: index)
        }
    }
    
    /// Scan one line of Textile, looking for signature.
    func scanForSignature() {
        
        let info = String(line[startOfInfo...])
        startChunk()
        if block.count > 0 {
            block.phase = .blockStarted
            return
        }
        var lastChar: Character = " "
        var index = line.startIndex
        for char in info {
            var skipPeriod = false
            if block.phase == .lookingForSignature {
                if TextileSignature.validModStart(char) && (type == .ordered || type == .unordered) {
                    block.phase = .mods
                } else if char == "." || TextileSignature.validModStart(char) {
                    if block.validSig {
                        if char == "." {
                            block.phase = .periodFound
                            skipPeriod = true
                        } else {
                            block.phase = .mods
                        }
                    } else {
                        // chunk.append(block.sig.sig)
                        block.sig.sig = ""
                        block.phase = .blockStarted
                        break
                    }
                } else if block.sig.sig.count > 8 {
                    // chunk.append(block.sig.sig)
                    block.sig.sig = ""
                    block.phase = .blockStarted
                    break
                } else {
                    block.appendToSig(char)
                }
            }
            
            if block.phase == .mods {
                if char.isWhitespace && (type == .ordered || type == .unordered) {
                    block.phase = .spacesStarted
                } else if char == "." {
                    block.phase = .periodFound
                    skipPeriod = true
                } else {
                    block.appendToMods(char)
                }
            }
            
            if block.phase == .periodFound && !skipPeriod {
                if char == "." {
                    block.sig.extended = true
                    skipPeriod = true
                    block.phase = .spacesStarted
                } else if char.isWhitespace {
                    block.phase = .spacesStarted
                } else {
                    block.phase = .blockStarted
                    startOfChunks = index
                    break
                }
            }
            
            if block.phase == .spacesStarted {
                if !skipPeriod && !char.isWhitespace {
                    block.phase = .blockStarted
                    startOfChunks = index
                    break
                }
            }
            
            lastChar = char
            index = line.index(after: index)
        } // end for each character in the line
    } // end scan func
    
    func scanForChunks() {
        let info = String(line[startOfChunks...])
        startChunk()
        var lastChar: Character = " "
        var priorLastChar: Character = " "
        var index = info.startIndex
        var nextIndex = index
        var nextChar: Character = " "
        var nextNextChar: Character = " "
        var nextNextIndex = index
        if nextNextIndex < info.endIndex {
            nextNextChar = info[nextNextIndex]
        }
        for char in info {
            
            // Line up the next two characters to make them available
            nextChar = " "
            nextIndex = info.index(after: index)
            nextNextIndex = nextIndex
            if nextIndex < info.endIndex {
                nextChar = info[nextIndex]
                nextNextIndex = info.index(after: nextIndex)
            }
            nextNextChar = " "
            if nextNextIndex < info.endIndex {
                nextNextChar = info[nextNextIndex]
            }
            var disp = TextileCharDisposition.text
            
            // If we're collecting characters that will make up an href value,
            // then check for a delimiter to end the collection.
            if openingLink != nil {
                if (char.isWhitespace
                    || char == "'" || char == "\"" || char == ")") {
                    openingLink = nil
                } else if char == "." && (nextChar == "_" || nextChar.isWhitespace) {
                    openingLink = nil
                } else {
                    disp = .href
                }
            }
            
            // Look for characters and character sequences with special meanings.
            if disp == .href {
                // skip further evaluation
            } else if char == "?" {
                if pendingChars == "?" {
                    chunk.possibleOpening("??")
                    pendingChars = ""
                    disp = .special
                } else {
                    disp = .pending
                }
            } else if char == "\"" {
                if lastChar == "\"" {
                    chunk.possibleOpening("a")
                    disp = .special
                } else {
                    chunk.special.append(char)
                    chunk.oc = .opening
                    disp = .special
                }
            } else if char == ":" && lastChar == "\"" {
                openingLink = checkForLink()
                if openingLink == nil {
                    disp = .text
                } else {
                    disp = .skip
                }
            } else if char == "'" {
                if lastChar.isWhitespace {
                    chunk.possibleOpening("'")
                    chunk.specialValid = true
                    disp = .special
                } else {
                    chunk.special = "'"
                    chunk.oc = .closing
                    chunk.specialValid = true
                    chunk.specialMatched = false
                    disp = .special
                }
            } else if char == "." {
                if pendingChars == ".." {
                    chunk.possibleOpening("...")
                    pendingChars = ""
                    disp = .special
                } else {
                    disp = .pending
                }
            } else if char == "-" && lastChar.isWhitespace && nextChar.isWhitespace {
                chunk.singularValid("-")
                disp = .special
            } else if char == "-" && lastChar == "-" && nextChar != "-" {
                chunk.singularValid("--")
                disp = .special
            } else if char == "-" && nextChar == "-" {
                disp = .skip
            } else if char == "_" {
                if pendingChars == "_" {
                    chunk.possibleOpening("__")
                    pendingChars = ""
                    disp = .special
                } else if nextChar == "_" {
                    flushPending()
                    disp = .pending
                } else {
                    chunk.possibleOpening("_")
                    disp = .special
                }
            }
            
            switch disp {
            case .pending:
                pendingChars.append(char)
            case .text:
                flushPending()
                chunk.append(char)
            case .special:
                flushPending()
                finishChunk()
                startChunk()
            case .href:
                openingLink!.href.append(char)
            case .skip:
                break
            }
            priorLastChar = lastChar
            lastChar = char
            index = info.index(after: index)
        }
        flushPending()
        finishChunk()
    }
    
    /// Push the pending characters onto the preceding text.
    func flushPending() {
        guard pendingChars.count > 0 else { return }
        chunk.append(pendingChars)
        pendingChars = ""
    }
    
    func startChunk() {
        chunk = TextileChunk()
        pendingChars = ""
        openingLink = nil
    }
    
    func finishChunk() {
        guard chunk.hasData else { return }
        if chunk.oc != .singular {
            checkForOpening()
        }
        chunks.append(chunk)
    }
    
    /// Check to see if this sequence of characters is the closing half of a matching pair,
    /// and then add the new sequence to the list.
    func checkForOpening() {
        
        var matchFound = false
        chunk.specialValid = false
        chunk.specialMatched = false
        block.startAtEnd()
        var priorChunk: TextileChunk? = block.priorChunk()
        while priorChunk != nil && !matchFound {
            if priorChunk!.special == chunk.special {
                matchFound = true
                if priorChunk!.oc == .opening {
                    priorChunk!.specialValid = true
                    priorChunk!.specialMatched = true
                    chunk.oc = .closing
                    chunk.specialValid = true
                    chunk.specialMatched = true
                }
            } else if priorChunk!.special == "a" && priorChunk!.oc == .opening
                && !priorChunk!.specialMatched && chunk.special == "\"" {
                matchFound = true
                priorChunk!.specialValid = true
                priorChunk!.specialMatched = true
                chunk.special = "a"
                chunk.oc = .closing
                chunk.specialValid = true
                chunk.specialMatched = true
            } else {
                priorChunk = block.priorChunk()
            }
        }
        
        if chunk.special == "'" && !chunk.specialValid && !chunk.specialMatched {
            chunk.specialValid = true
            chunk.specialMatched = false
            chunk.oc = .singular
        }
    }
    
    /// After finding a colon that followed a double quotation mark, look for an
    /// opening quotation and, if found, mark it as the beginning of a hyperlink,
    /// rather than a literal quotation mark.
    func checkForLink() -> TextileChunk? {
        block.startAtEnd()
        var priorChunk = block.priorChunk()
        guard let endingQuote = priorChunk else {
            block.displayChunks()
            return nil
        }
        guard endingQuote.special == "\"" || endingQuote.special == "a" else { return nil }
        guard endingQuote.oc == .closing else { return nil }
        var openingQuoteFound = false
        priorChunk = block.priorChunk()
        while priorChunk != nil && !openingQuoteFound {
            if (priorChunk!.special == "\"" || priorChunk!.special == "a")
                && priorChunk!.oc == .opening {
                openingQuoteFound = true
            } else {
                priorChunk = block.priorChunk()
            }
        }
        guard let openingQuote = priorChunk else { return nil }
        guard openingQuoteFound else { return nil }
        openingQuote.special = "a"
        openingQuote.specialValid = true
        openingQuote.specialMatched = true
        openingQuote.href = ""
        endingQuote.special = "a"
        endingQuote.specialValid = true
        endingQuote.specialMatched = true
        return openingQuote
    }
}

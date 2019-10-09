//
//  TextileBlock.swift
//  Notenik
//
//  Created by Herb Bowie on 10/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Textile Block including its signature, along with any formatting modifiers,
/// plus its lines, broken up into chunks.
class TextileBlock {
    
    var phase: TextileBlockPhase = .lookingForSignature
    var sig =  TextileSignature()
    var lines: [TextileLine] = []
    
    var lineIndex = 0
    var chunkIndex = 0
    
    /// Initialize with no input. 
    init() {
        
    }
    
    /// Initialize with a string identifying a Textile signature.
    convenience init(sig: String) {
        self.init()
        self.sig = TextileSignature(sig: sig)
    }
    
    func appendToSig(_ char: Character) {
        sig.append(char)
    }
    
    func appendToMods(_ char: Character) {
        sig.mods.append(char)
    }
    
    /// Is the block's signature valid?
    var validSig: Bool {
        return sig.valid
    }
    
    func appendLine(_ line: TextileLine) {
        lines.append(line)
        line.block = self
    }
    
    /// Returns the number of lines in the block.
    var count: Int {
        return lines.count
    }
    
    /// Used for Debugging
    func displayChunks() {
        startAtTop()
        var (next, _) = nextChunk()
        while next != nil {
            next!.display()
            (next, _) = nextChunk()
        }
    }
    
    /// Set line and chunk indices to start with the first chunk of the first line.
    func startAtTop() {
        lineIndex = 0
        startAtBeginningOfLine()
    }
    
    /// Return the next chunk, in ascending order, or nil at the end.
    func nextChunk() -> (TextileChunk?, Bool) {
        while lineIndex < lines.count && chunkIndex >= lines[lineIndex].chunks.count {
            lineIndex += 1
            startAtBeginningOfLine()
        }
        if lineIndex >= lines.count {
            return (nil, false)
        } else {
            let chunk = lines[lineIndex].chunks[chunkIndex]
            var lineBreak = false
            chunkIndex += 1
            if chunkIndex >= lines[lineIndex].chunks.count {
                lineIndex += 1
                lineBreak = (lineIndex < lines.count)
                startAtBeginningOfLine()
            }
            return (chunk, lineBreak)
        }
    }
    
    /// Reset the chunk index to zero.
    func startAtBeginningOfLine() {
        chunkIndex = 0
    }
    
    /// Start with the last chunk of the last line.
    func startAtEnd() {
        lineIndex = lines.count - 1
        startAtEndOfLine()
    }
    
    /// Return the prior chunk, or nil when the top is reached.
    func priorChunk() -> TextileChunk? {
        
        while lineIndex >= 0 && chunkIndex >= lines[lineIndex].chunks.count {
            lineIndex -= 1
            startAtEndOfLine()
        }
        if lineIndex < 0 || chunkIndex < 0 {
            return nil
        } else {
            let chunk = lines[lineIndex].chunks[chunkIndex]
            chunkIndex -= 1
            if chunkIndex < 0 {
                lineIndex -= 1
                startAtEndOfLine()
            }
            return chunk
        }
    }
    
    /// Start with the last chunk of the current line.
    func startAtEndOfLine() {
        if lineIndex >= 0 && lineIndex < lines.count {
            chunkIndex = lines[lineIndex].chunks.count - 1
        } else {
            chunkIndex = 0
        }
    }
    
}

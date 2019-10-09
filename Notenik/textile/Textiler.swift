//
//  Textiler.swift
//  Notenik
//
//  Created by Herb Bowie on 10/2/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class to convert textile to HTML. The Textile code will be broken down into:
/// * Blocks, separated by blank lines.
/// * Lines, ended by a carriage return and/or a newline
/// * Chunks, consisting of text streams, followed by character strings with some
///   special meaning within Textile.
class Textiler {
    
    var extendedSig = TextileSignature()
    
    var block = TextileBlock()
    
    var pendingBlockQuote = false
    
    var markedup = Markedup(format: .htmlFragment)
    
    /// Convert some textile code to HTML.
    func toHTML(textile: String) -> String {

        markedup.startDoc(withTitle: nil, withCSS: nil)
 
        let reader = BigStringReader(textile)
        reader.open()
        startBlock()
        var line = reader.readLine()
        while line != nil {
            let textileLine = TextileLine(line: line!)
            textileLine.scanForLineType()
            if textileLine.type == .blank {
                finishBlock()
                startBlock()
            } else {
                textileLine.block = block
                if block.sig.html {
                    textileLine.type = .html
                }
                if textileLine.type == .html {
                    block.sig.sig = "html"
                    block.sig.mods = ""
                    block.appendLine(textileLine)
                    let htmlChunk = TextileChunk()
                    htmlChunk.preceding = line!
                    htmlChunk.special = "html-line"
                    textileLine.chunks.append(htmlChunk)
                } else {
                    textileLine.scanForSignature()
                    block.appendLine(textileLine)
                    textileLine.scanForChunks()
                }
            }
            line = reader.readLine()
        }
        finishBlock()
        
        markedup.finishDoc()
        return markedup.code
    }
    
    func startBlock() {
        block = TextileBlock()
    }
    
    func finishBlock() {
        
        guard block.count > 0 else { return }
        // Now let's figure out what sort of signature to use for the block.
        if block.sig.valid {
            if pendingBlockQuote {
                markedup.finishBlockQuote()
                pendingBlockQuote = false
            }
            extendedSig = TextileSignature()
        } else if extendedSig.valid {
            extendedSig.extBlockCount += 1
            block.sig = extendedSig
        } else {
            block.sig = TextileSignature(sig: "p")
        }
        if block.sig.extended {
            extendedSig = block.sig
        }
        pendingBlockQuote = extendedSig.valid && extendedSig.blockQuote
        block.sig.openBlock(markedup: markedup)
        
        // Now let's go through the lines and chunks within the block,
        // generating HTML as we go.
        var lineIndex = 0
        for line in block.lines {
            
            // Finish up any outstanding lists
            if markedup.listInProgress == "u" && line.type != .unordered {
                markedup.finishUnorderedList()
            } else if markedup.listInProgress == "o" && line.type != .ordered {
                markedup.finishOrderedList()
            }
            
            // Start any new lists
            if line.type == .ordered && markedup.listInProgress != "o" {
                markedup.startOrderedList()
            } else if line.type == .unordered && markedup.listInProgress != "u" {
                markedup.startUnorderedList()
            }
            
            if line.type == .ordered || line.type == .unordered {
                markedup.startListItem()
            }
            
            var chunkIndex = 0
            var lastChunk = TextileChunk()
            for chunk in line.chunks {
                chunk.toMarkup(markedup: markedup)
                lastChunk = chunk
                chunkIndex += 1
            } // end of chunks in line
            
            if line.type == .ordered || line.type == .unordered {
                markedup.finishListItem()
            } else if lineIndex < block.lines.count && !block.sig.html && lastChunk.special != "html-line" {
                markedup.lineBreak()
            }
                
            lineIndex += 1
        } // end of lines in block
        
        // Finish up any lists still in progress
        if markedup.listInProgress == "u" {
            markedup.finishUnorderedList()
        } else if markedup.listInProgress == "o" {
            markedup.finishOrderedList()
        }
        
        block.sig.closeBlock(markedup: markedup)
    }
    
}

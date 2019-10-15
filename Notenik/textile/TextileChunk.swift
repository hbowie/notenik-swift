//
//  TextileChunk.swift
//  Notenik
//
//  Created by Herb Bowie on 10/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A sequence of one or more characters with some special meaning in Textile, plus preceding/following text.
class TextileChunk {
    var preceding = ""
    var special = ""
    var specialValid = true
    var specialMatched = false
    var oc: TextileOpeningClosing = .singular
    var href = ""
    
    /// Initialize with default values.
    init() {

    }
    
    /// Initialize with the sequence of characters that might have some special meaning within Textile.
    convenience init(special: String) {
        self.init()
        self.special = special
    }
    
    /// Append more text to the chunk of text preceding any special characters. 
    func append(_ str: String) {
        preceding.append(str)
    }
    
    /// Append another character to the chunk of text preceding any special characters. 
    func append(_ char: Character) {
        preceding.append(char)
    }
    
    func singularValid(_ special: String) {
        self.special = special
        specialValid = true
        specialMatched = false
        oc = .singular
    }
    
    func possibleOpening(_ special: String) {
        self.special = special
        specialValid = false
        specialMatched = false
        oc = .opening
    }
    
    /// Does this chunk actually have any data?
    var hasData: Bool {
        return preceding.count > 0 || special.count > 0
    }
    
    /// Convert this chunk to appropriate markup. 
    func toMarkup(markedup: Markedup) {
        
        if preceding.count > 0 {
            markedup.append(preceding)
        }
        
        if specialValid {
            switch special {
            case "??":
                if oc == .opening {
                    markedup.startCite()
                } else {
                    markedup.finishCite()
                }
            case "a":
                if oc == .opening {
                    markedup.startLink(path: href)
                } else {
                    markedup.finishLink()
                }
            case "\"":
                if oc == .opening {
                    markedup.leftDoubleQuote()
                } else {
                    markedup.rightDoubleQuote()
                }
            case "'":
                if oc == .opening && specialMatched {
                    markedup.leftSingleQuote()
                } else {
                    markedup.rightSingleQuote()
                }
            case "-":
                markedup.shortDash()
            case "--":
                markedup.longDash()
            case "...":
                markedup.ellipsis()
            case "__":
                if oc == .opening {
                    markedup.startItalics()
                } else {
                    markedup.finishItalics()
                }
            case "_":
                if oc == .opening {
                    markedup.startEmphasis()
                } else {
                    markedup.finishEmphasis()
                }
            case ":":
                markedup.finishDefTerm()
                markedup.startDefDef()
            case "html-line":
                markedup.newLine()
            default:
                break
            }
        } else {
            markedup.append(special)
        }
    }
    
    /// Used for debugging
    func display() {
        print("Chunk special = '\(special)' valid? \(specialValid) matched? \(specialMatched) open/close = \(oc) preceding = \(preceding)")
    }
}

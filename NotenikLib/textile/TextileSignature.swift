//
//  TextileSignature.swift
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

/// The signature optionally appearing at the beginning of a Textile block.
class TextileSignature {
    
    var sig = ""
    var mods = ""
    var id = ""
    var klass = ""
    var extended = false
    var extBlockCount = 0
    
    /// Initialize with default values.
    init() {
        
    }
    
    /// Initialize with the string identifying the type of block.
    convenience init(sig: String) {
        self.init()
        self.sig = sig
    }
    
    /// Append another character to a possible signature string. 
    func append(_ char: Character) {
        sig.append(char)
    }
    
    /// Is the signature recognized?
    var valid: Bool {
        return sig.count > 0 && TextileSignature.validSig(sig)
    }
    
    /// Is this a signature for a block quote?
    var blockQuote: Bool {
        return sig == "bq"
    }
    
    /// Is this a line of HTML?
    var html: Bool {
        return sig == "html"
    }
    
    func evalMods() {
        var expectingKlassOrID = false
        var expectingID = false
        for char in mods {
            if char == "(" {
                expectingKlassOrID = true
            } else if char == "#" {
                expectingID = true
            } else if char == ")" {
                expectingID = false
                expectingKlassOrID = false
            } else if expectingID {
                id.append(char)
            } else if expectingKlassOrID {
                klass.append(char)
            }
        }
    }
    
    /// Generate the appropriate markup to begin the block. 
    func openBlock(markedup: Markedup) {
        evalMods()
        var sigType = sig
        var headingLevel: Int? = 1
        if !html && sig.starts(with: "h") {
            sigType = "h"
            headingLevel = Int(sig.suffix(1))
        }
        switch sigType {
        case "bq":
            if extBlockCount == 0 {
                markedup.startBlockQuote()
            }
            markedup.startParagraph()
        case "h":
            markedup.startHeading(level: headingLevel!)
        case "p":
            markedup.startParagraph(klass: klass)
        default:
            break
        }
    }
    
    /// Generate the appropriate markup to end the block. 
    func closeBlock(markedup: Markedup) {
        var sigType = sig
        var headingLevel: Int? = 1
        if !html && sig.starts(with: "h") {
            sigType = "h"
            headingLevel = Int(sig.suffix(1))
        }
        switch sigType {
        case "bq":
            markedup.finishParagraph()
            if !extended {
                markedup.finishBlockQuote()
            }
        case "h":
            markedup.finishHeading(level: headingLevel!)
        case "p":
            markedup.finishParagraph()
        default:
            break
        }
    }
    
    /// Is the passed string a valid textile block signature?
    static func validSig(_ sig: String) -> Bool {
        switch sig {
        case "p":
            return true
        case "h1", "h2", "h3", "h4", "h5", "h6":
            return true
        case "pre", "bc", "bq":
            return true
        case "###":
            return true
        case "notextile":
            return true
        case "html":
            return true
        default:
            return false
        }
    }
    
    /// Is this character a valid start to a possible string of formatting modifiers?
    static func validModStart(_ char: Character) -> Bool {
        switch char {
        case "(", ")", "<", ">", "=", "{", "[":
            return true
        default:
            return false
        }
    }

}

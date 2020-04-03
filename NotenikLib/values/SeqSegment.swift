//
//  SeqSegment.swift
//  Notenik
//
//  Created by Herb Bowie on 3/10/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class SeqSegment {
    
    var value = ""
    var padChar:     Character = " "
    var punctuation: Character = " "
    var digits       = false
    var letters      = false
    var allUppercase = true
    
    func append(_ c: Character) {
        if c == "0" && count == 0 {
            padChar = c
        } else if c.isWhitespace {
            // Ignore whitespace
        } else if c == "$" {
            value.append(c)
        } else if c == "'" {
            value.append(c)
        } else if c == "_" {
            value.append(c)
        } else if c == "," {
            value.append(c)
        } else if StringUtils.isAlpha(c) {
            value.append(c)
            letters = true
            if StringUtils.isLower(c) {
                allUppercase = false
            }
        } else if StringUtils.isDigit(c) {
            value.append(c)
            digits = true
        } else if c == "." || c == "-" {
            if value.count == 0 {
                value.append("0")
            }
            punctuation = c
        } // end character evaluation
    }
    
    var count: Int {
        return value.count
    }
    
    func pad(padChar: Character, padTo: Int, padLeft: Bool = true) -> String {
        var padded = ""
        if padLeft {
            var chars = count
            while chars < padTo {
                padded.append(padChar)
                chars += 1
            }
        }
        padded.append(value)
        if !padLeft {
            var chars = padded.count
            while chars < padTo {
                padded.append(padChar)
                chars += 1
            }
        }
        return padded
    }
    
}

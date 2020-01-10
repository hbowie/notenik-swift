//
//  NoteLineIn.swift
//  Notenik
//
//  Created by Herb Bowie on 1/2/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single line from an input Notenik file.
class NoteLineIn {
    
    // Input fields
    var line         = ""
    var collection   : NoteCollection!
    var bodyStarted  = false

    var colonCount   = 0
    var firstChar:     Character?

    var index:         String.Index
    var nextIndex:     String.Index

    var allOneChar   = false
    var allOneCharCount = 0
    var blankLine    = false
    var lastLine     = false
    var mdH1Line     = false
    var mdTagsLine   = false
    var mmdMetaStartEndLine = false
    
    var firstIndex   : String.Index
    var lastIndex    : String.Index
    
    var colonIndex:    String.Index
    var colonFound   = false

    var validLabel   = false
    var label        = FieldLabel()
    var definition:    FieldDefinition?
    var value        = ""
    
    init(line: String?, collection: NoteCollection, bodyStarted: Bool) {
        
        if line == nil {
            self.line = ""
            lastLine = true
        } else {
            self.line = line!
        }
        self.collection = collection
        self.bodyStarted = bodyStarted
        
        index      = self.line.startIndex
        nextIndex  = self.line.startIndex
        colonIndex = self.line.startIndex
        firstIndex = self.line.startIndex
        lastIndex  = self.line.endIndex
        
        definition = FieldDefinition()
        
        if self.line.starts(with: "# ") {
            mdH1Line = true
            value = StringUtils.trimHeading(self.line)
        } else if self.line.starts(with: "#")
            && !self.line.starts(with: "# ")
            && !self.line.starts(with: "##") {
            mdTagsLine = true
            value = StringUtils.trimHeading(self.line)
        } else {
            scanLine()
        }
    }
    
    /// Scan the line and collect relevant info about it
    func scanLine() {
        
        validLabel = false
        label = FieldLabel()
        value  = ""
        colonFound = false
        blankLine = true
        allOneChar = true
        allOneCharCount = 0
        firstChar = nil

        var badLabelPunctuationCount = 0
        var offset = 0
        for c in line {
            nextIndex = line.index(index, offsetBy: 1)
            // See if the line conists of one character repeated multiple times
            if firstChar == nil {
                firstChar = c
                allOneCharCount = 1
            } else if allOneChar && c == firstChar {
                allOneCharCount += 1
                if firstChar == "-" && allOneCharCount == 3 {
                    mmdMetaStartEndLine = true
                } else if firstChar == "." && allOneCharCount == 4 {
                    mmdMetaStartEndLine = true
                }
            } else {
                allOneChar = false
            }
            
            // See if we have a completely blank line
            if !StringUtils.isWhitespace(c) {
                blankLine = false
            }
            
            if c == ":" {
                colonCount += 1
                if colonCount == 1 && badLabelPunctuationCount == 0 && !bodyStarted {
                    colonFound = true
                    colonIndex = index
                    label.set(StringUtils.trim(String(line[line.startIndex..<index])))
                    definition = collection.getDef(label: &label)
                    validLabel = label.validLabel
                    if validLabel && index < line.endIndex {
                        value = StringUtils.trim(String(line[nextIndex..<line.endIndex]))
                    }
                }
            } else if c == "," || c == "[" || c == "]" || c == "(" || c == ")" {
                badLabelPunctuationCount += 1
            }
            index = nextIndex
            offset += 1
        } // end for each character in line
    } // end scanLine method
}

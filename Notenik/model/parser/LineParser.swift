//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Read lines in the Notenik format, and create a Note from their content.
class LineParser {
    
    var lineReader   : LineReader
    var note         : Note
    
    var possibleLine : String?
    var line         = ""
    var trailingSpaceCount = 0
    var firstIndex   : String.Index
    var lastIndex    : String.Index
    var index        : String.Index
    var nextIndex    : String.Index
    var colonIndex   : String.Index
    var colonFound   = false
    
    var possibleLabel: FieldLabel
    var possibleDef  : FieldDefinition?
    var nextValue    = ""
    
    var label        : FieldLabel
    var def          : FieldDefinition
    var value        = ""
    var pendingBlankLines = 0
    
    var firstChar    : Character?
    var blankLine    = true
    var oneChar      = true
    var bodyStarted  = false
    
    var lineNumber   = 0
    var fileSize     = 0
    
    /// Default initializer with nothing to read
    init() {
        lineReader = BigStringReader()
        note       = Note()
        line       = ""
        possibleLine = ""
        firstIndex = line.startIndex
        lastIndex = line.endIndex
        index = line.startIndex
        nextIndex = line.startIndex
        colonIndex = line.startIndex
        possibleLabel = FieldLabel()
        label = FieldLabel()
        def = FieldDefinition()
    }
    
    /// Initialize with a functioning Line Reader
    convenience init (collection : NoteCollection, lineReader : LineReader) {
        self.init()
        note.collection = collection
        self.lineReader = lineReader
    }
    
    /// Get the Note from the input lines
    func getNote() -> Note {
        lineNumber = 0
        fileSize   = 0
        bodyStarted = false
        possibleLabel = FieldLabel()
        label = FieldLabel()
        pendingBlankLines = 0
        bodyStarted = false
        lineReader.open()
        repeat {
            readLine()
            // If we've reached the end of the file, or the label for a new field,
            // then finish up the last field we were working on.
            if possibleLine == nil || possibleLabel.isValid() {
                if label.isValid() && value.count > 0 {
                    let field = NoteField(def: def, value: value)
                    note.setField(field)
                }
            }
            
            if possibleLine == nil {
                // We're done
            } else if possibleLabel.isValid() {
                label = possibleLabel
                def   = possibleDef!
                value = nextValue
                if label.isBody {
                    bodyStarted = true
                }
            } else if blankLine {
                if value.count > 0 {
                    pendingBlankLines += 1
                }
            } else if label.isValid() {
                appendNonBlankLine()
            } else if note.containsTitle() {
                label.set(LabelConstants.body)
                def = note.collection.getDef(label: &label)!
                value = line
                bodyStarted = true
            } else {
                let titleField = NoteField(label: LabelConstants.title,
                                           value: StringUtils.trimHeading(line))
                note.setField(titleField)
            }
        } while possibleLine != nil
        lineReader.close()
        return note
    }
    
    // Read the next line from the reader
    func readLine() {
        possibleLine = lineReader.readLine()
        possibleLabel = FieldLabel()
        if possibleLine == nil {
            line = ""
        } else {
            line = possibleLine!
            scanLine()
        }
    }
    
    /// Scan the line and collect relevant info about it
    func scanLine() {
        
        lineNumber += 1
        fileSize += line.count + 1
        
        firstIndex = line.startIndex
        lastIndex  = line.endIndex
        index      = line.startIndex
        nextIndex  = line.startIndex
        colonIndex = line.startIndex
        possibleLabel = FieldLabel()
        nextValue  = ""
        colonFound = false
        blankLine = true
        oneChar = true
        firstChar = nil
        var colonCount = 0
        var commaCount = 0
        var offset = 0
        for c in line {
            nextIndex = line.index(index, offsetBy: 1)
            // See if the line conists of one character repeated multiple times
            if firstChar == nil {
                firstChar = c
            } else if c != firstChar {
                oneChar = false
            }
            
            // See if we have a completely blank line
            if !StringUtils.isWhitespace(c) {
                blankLine = false
            }
            
            var validLabel = false
            if c == ":" {
                colonCount += 1
                if colonCount == 1 && commaCount == 0 && !bodyStarted {
                    colonFound = true
                    colonIndex = index
                    possibleLabel.set(StringUtils.trim(String(line[line.startIndex..<index])))
                    possibleDef = note.collection.getDef(label: &possibleLabel)
                    validLabel = possibleLabel.isValid()
                    if validLabel && index < line.endIndex {
                        nextValue = StringUtils.trim(String(line[nextIndex..<line.endIndex]))
                    }
                }
            } else if c == "," {
                commaCount += 1
            }
            index = nextIndex
            offset += 1
        } // end for each character in line
        
    }
    
    func appendNonBlankLine() {
        while pendingBlankLines > 0 && value.count > 0 {
            value.append("\n")
            pendingBlankLines -= 1
        }
        value.append(line)
        value.append("\n")
    }
    
}

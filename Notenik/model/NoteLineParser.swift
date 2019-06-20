//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Read lines in the Notenik format, and create a Note from their content.
class NoteLineParser {
    
    var collection:     NoteCollection
    var lineReader:     LineReader
    
    var note:           Note
    
    var possibleLine : String?
    var line         = ""
    var trailingSpaceCount = 0
    var firstIndex   : String.Index
    var lastIndex    : String.Index
    var index        : String.Index
    var nextIndex    : String.Index
    var colonIndex   : String.Index
    var colonFound   = false
    
    var possibleLabel = FieldLabel()
    var possibleDef:    FieldDefinition?
    var nextValue    = ""
    
    var label        = FieldLabel()
    var def          = FieldDefinition()
    var value        = ""
    var pendingBlankLines = 0
    
    var firstChar    : Character?
    var blankLine    = true
    var oneChar      = true
    var bodyStarted  = false
    
    var lineNumber   = 0
    var fileSize     = 0
    
    /// Initialize with a functioning Line Reader
    init (collection: NoteCollection, lineReader: LineReader) {
        
        self.collection = collection
        self.lineReader = lineReader
        
        note = Note(collection: collection)
        
        firstIndex = line.startIndex
        lastIndex = line.endIndex
        nextIndex = line.startIndex
        colonIndex = line.startIndex
        index = line.startIndex
        
        initVars()
    }
    
    /// Initialize key variables before beginning the parsing of another note.
    func initVars() {
        note = Note(collection: collection)
        note.collection = collection
        line = ""
        possibleLine = ""
        firstIndex = line.startIndex
        lastIndex = line.endIndex
        nextIndex = line.startIndex
        colonIndex = line.startIndex
        index = line.startIndex
        possibleLabel = FieldLabel()
        label = FieldLabel()
        def = FieldDefinition()
        lineNumber = 0
        fileSize   = 0
        bodyStarted = false
        pendingBlankLines = 0
    }
    
    /// Get the Note from the input lines
    func getNote(defaultTitle: String) -> Note {
        initVars()
        lineReader.open()
        repeat {
            
            readLine()
            
            // If we've reached the end of the file, or the label for a new field,
            // then finish up the last field we were working on.
            if possibleLine == nil || possibleLabel.validLabel {
                if label.validLabel && value.count > 0 {
                    let field = NoteField(def: def, value: value, statusConfig: collection.statusConfig)
                    note.setField(field)
                }
                pendingBlankLines = 0
            }
            
            // Now figure out what to do with this line.
            if possibleLine == nil {
                // We're done
            } else if possibleLabel.validLabel {
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
            } else if label.validLabel {
                appendNonBlankLine()
            // } else if note.containsTitle() {
            } else {
                label.set(LabelConstants.body)
                def = note.collection.getDef(label: &label)!
                value = line
                bodyStarted = true
            }
            /* else {
                let titleField = NoteField(label: LabelConstants.title,
                                           value: StringUtils.trimHeading(line))
                note.setField(titleField)
            } */
            
            // Don't allow the title field to consume multiple lines. 
            if label.isTitle && value.count > 0 {
                let titleField = NoteField(def: def, value: value, statusConfig: collection.statusConfig)
                note.setField(titleField)
                pendingBlankLines = 0
                label = FieldLabel()
                value = ""
            }
        } while possibleLine != nil
        lineReader.close()
        if !note.hasTitle() {
            note.setTitle(defaultTitle)
        }
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
                    validLabel = possibleLabel.validLabel
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
        pendingBlankLines = 0
    }
    
}

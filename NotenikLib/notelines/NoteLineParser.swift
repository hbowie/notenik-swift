//
//  LineParser.swift
//  Notenik
//
//  Created by Herb Bowie on 12/10/18.
//  Copyright © 2018 - 2020 Herb Bowie (https://powersurgepub.com)
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
    
    var textLine: String?
    var noteLine: NoteLineIn!
    
    var trailingSpaceCount = 0
    
    var label        = FieldLabel()
    var def          = FieldDefinition()
    var value        = ""
    var valueLines   = 0
    var pendingBlankLines = 0
    
    var bodyStarted  = false
    var indexStarted = false
    
    var lineNumber   = 0
    var fieldNumber  = 0
    var blankLines   = 0
    var fileSize     = 0
    
    /// Initialize with a functioning Line Reader
    init (collection: NoteCollection, lineReader: LineReader) {
        
        self.collection = collection
        self.lineReader = lineReader
        
        note = Note(collection: collection)
        
    }
    
    /// Get the Note from the input lines
    func getNote(defaultTitle: String) -> Note {
        
        note = Note(collection: collection)
        label = FieldLabel()
        def = FieldDefinition()
        clearValue()
        
        lineNumber = 0
        fieldNumber = 0
        blankLines = 0
        fileSize   = 0
        bodyStarted = false
        indexStarted = false
        pendingBlankLines = 0
        var valueComplete = false
        
        lineReader.open()
        repeat {
            textLine = lineReader.readLine()
            noteLine = NoteLineIn(line: textLine,
                                  collection: collection,
                                  bodyStarted: bodyStarted)
            lineNumber += 1
            fileSize += noteLine.line.count + 1
            if noteLine.blankLine {
                blankLines += 1
            }
            
            if label.validLabel && value.count > 0 && !bodyStarted {
                if noteLine.blankLine && blankLines == 1 && fieldNumber > 1 {
                    valueComplete = true
                } else if fieldNumber == 1 {
                    valueComplete = true
                } else if noteLine.mmdMetaStartEndLine
                    && note.fileInfo.format == .multiMarkdown {
                    valueComplete = true
                }
            }
            
            // If we've reached the end of the file, or the label for a new field,
            // then finish up the last field we were working on.
            if noteLine.lastLine
                || noteLine.validLabel
                || valueComplete {
                captureLastField()
            }
            
            valueComplete = false
            
            // Now figure out what to do with this line.
            if noteLine.mmdMetaStartEndLine && lineNumber == 1 {
                note.fileInfo.format = .multiMarkdown
                note.fileInfo.mmdMetaStartLine = noteLine.line
            } else if noteLine.mmdMetaStartEndLine
                && note.fileInfo.format == .multiMarkdown
                && !bodyStarted {
                note.fileInfo.mmdMetaEndLine = noteLine.line
            } else if lineNumber == 1 && noteLine.mdH1Line && noteLine.value.count > 0 && !bodyStarted {
                label.set(LabelConstants.title)
                label.validLabel = true
                def = note.collection.getDef(label: &label)!
                value = noteLine.value
                note.fileInfo.format = .markdown
            } else if note.fileInfo.format == .markdown && !bodyStarted && noteLine.mdTagsLine {
                label.set(LabelConstants.tags)
                label.validLabel = true
                def = note.collection.getDef(label: &label)!
                value = noteLine.value
                valueComplete = true
            } else if noteLine.validLabel {
                label = noteLine.label
                def   = noteLine.definition!
                value = noteLine.value
                if label.isBody {
                    bodyStarted = true
                }
            } else if noteLine.blankLine {
                if fieldNumber > 1 && blankLines == 1 && !bodyStarted {
                    note.fileInfo.format = .multiMarkdown
                    label.set(LabelConstants.body)
                    label.validLabel = true
                    def = note.collection.getDef(label: &label)!
                    clearValue()
                    bodyStarted = true
                } else {
                    if value.count > 0 {
                        pendingBlankLines += 1
                    }
                }
            } else if label.validLabel {
                appendNonBlankLine()
            // } else if note.containsTitle() {
            } else {
                // Value with no label
                label.set(LabelConstants.body)
                label.validLabel = true
                def = note.collection.getDef(label: &label)!
                value = noteLine.line
                bodyStarted = true
                if lineNumber == 1 {
                    note.fileInfo.format = .plainText
                } else {
                    note.fileInfo.format = .multiMarkdown
                }
            }
            /* else {
                let titleField = NoteField(label: LabelConstants.title,
                                           value: StringUtils.trimHeading(line))
                note.setField(titleField)
            } */
            
            // Don't allow the title field to consume multiple lines. 
            if label.isTitle && value.count > 0 {
                valueComplete = true
            }
            
        } while !noteLine.lastLine
        
        lineReader.close()
        if !note.hasTitle() {
            _ = note.setTitle(defaultTitle)
        }
        return note
    }
    
    /// Add the last field found to the note.
    func captureLastField() {
        
        pendingBlankLines = 0
        guard label.validLabel && value.count > 0 else { return }
        let field = NoteField(def: def, value: value, statusConfig: collection.statusConfig)
        if field.def.fieldLabel.isIndex {
            if indexStarted {
                note.appendToIndex(value)
            } else {
                _ = note.setIndex(value)
                indexStarted = true
            }
        } else {
            _ = note.setField(field)
        }
        fieldNumber += 1
        label = FieldLabel()
        clearValue()
    }
    
    func appendNonBlankLine() {
        if value.count > 0 && valueLines == 0 {
            valueNewLine()
        }
        while pendingBlankLines > 0 && value.count > 0 {
            valueNewLine()
            pendingBlankLines -= 1
        }
        value.append(noteLine.line)
        valueNewLine()
        pendingBlankLines = 0
    }
    
    func valueNewLine() {
        value.append("\n")
        valueLines += 1
    }
    
    func clearValue() {
        value = ""
        valueLines = 0
    }
    
}

//
//  LineMaker.swift
//  Notenik
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Format a note as a series of text lines. 
class NoteLineMaker {
    
    var writer: LineWriter
    let minCharsToValue = 8
    var fieldsWritten = 0
    
    /// Initialize with no input, assuming the writer will be a Big String Writer.
    init() {
        writer = BigStringWriter()
    }
    
    /// Initialize with the Line Writer to be used.
    ///
    /// - Parameter writer: The line writer to be used.
    init(_ writer: LineWriter) {
        self.writer = writer
    }
    
    /// Format all of a note's fields and send them to the writer.
    ///
    /// - Parameter note: The note to be written.
    /// - Returns: The number of fields written.
    func putNote(_ note: Note) -> Int {
        
        if note.fileInfo.format == .toBeDetermined {
            note.fileInfo.format = .notenik
        }
        
        /// If we have more data than can fit in a restricted format,
        /// then switch to the Notenik format.
        if note.fileInfo.format != .notenik
            && note.fileInfo.format != .multiMarkdown {
            for def in note.collection.dict.list {
                let field = note.getField(def: def)
                if field != nil && field!.value.hasData {
                    if def.fieldLabel.commonForm == LabelConstants.title
                        || def.fieldLabel.commonForm == LabelConstants.body {
                        break
                    } else if def.fieldLabel.commonForm == LabelConstants.tags {
                        if note.fileInfo.format == .multiMarkdown {
                            break
                        } else {
                            note.fileInfo.format = .notenik
                        }
                    } else {
                        note.fileInfo.format = .notenik
                    }
                }
            }
        }
        fieldsWritten = 0
        writer.open()
        if note.fileInfo.format == .multiMarkdown && note.fileInfo.mmdMetaStartLine.count > 0 {
            writer.writeLine(note.fileInfo.mmdMetaStartLine)
        }
        if note.hasTitle() {
            putTitle(note)
        }
        if note.hasTags() {
            putTags(note)
        }
        var i = 0
        while i < note.collection.dict.count {
            let def = note.collection.dict.getDef(i)
            if def != nil &&
                def!.fieldLabel.commonForm != LabelConstants.titleCommon &&
                def!.fieldLabel.commonForm != LabelConstants.bodyCommon &&
                def!.fieldLabel.commonForm != LabelConstants.tagsCommon {
                putField(note.getField(def: def!), format: note.fileInfo.format)
            }
            i += 1
        }
        if note.fileInfo.format == .multiMarkdown && note.fileInfo.mmdMetaEndLine.count > 0 {
            writer.writeLine(note.fileInfo.mmdMetaEndLine)
            writer.endLine()
        }
        if note.hasBody() {
            putBody(note)
        }
        writer.close()
        return fieldsWritten
    }
    
    func putTitle(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            writer.writeLine("# \(note.title.value)")
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        case .notenik:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        case .plainText:
            break
        default:
            putField(note.getTitleAsField(), format: note.fileInfo.format)
        }
    }
    
    func putTags(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            writer.writeLine("#\(note.tags.value)")
            fieldsWritten += 1
        case .multiMarkdown:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        case .notenik:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        case .plainText:
            break
        default:
            putField(note.getTagsAsField(), format: note.fileInfo.format)
        }
    }
    
    func putBody(_ note: Note) {
        switch note.fileInfo.format {
        case .markdown:
            putFieldValue(note.body)
            fieldsWritten += 1
        case .multiMarkdown:
            writer.endLine()
            putFieldValue(note.body)
            fieldsWritten += 1
        case .notenik:
            putField(note.getBodyAsField(), format: note.fileInfo.format)
        case .plainText:
            putFieldValue(note.body)
            fieldsWritten += 1
        default:
            putField(note.getBodyAsField(), format: note.fileInfo.format)
        }
    }
    
    /// Write a field's label and value, along with the usual Notenik formatting.
    ///
    /// - Parameter field: The Note Field to be written.
    func putField(_ field: NoteField?, format: NoteFileFormat) {
        if field != nil && field!.value.hasData {
            putFieldName(field!.def, format: format)
            putFieldValue(field!.value)
            fieldsWritten += 1
        }
    }
    
    /// Write the field label to the writer, along with any necessary preceding and following text.
    ///
    /// - Parameter def: The Field Definition for the field.
    func putFieldName(_ def: FieldDefinition, format: NoteFileFormat) {
        if fieldsWritten > 0 && format == .notenik {
            writer.endLine()
        }
        let proper = def.fieldLabel.properForm
        writer.write(proper)
        writer.write(": ")
        if def.fieldType.isTextBlock {
            writer.endLine()
            writer.endLine()
        } else {
            var charsWritten = proper.count + 2
            while charsWritten < minCharsToValue {
                writer.write(" ")
                charsWritten += 1
            }
        }
    }
    
    /// Write the field value to the writer.
    ///
    /// - Parameter value: A StringValue or one of its descendants.
    func putFieldValue(_ value: StringValue) {
        writer.writeLine(value.value)
    }
}

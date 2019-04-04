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
    init(writer: LineWriter) {
        self.writer = writer
    }
    
    /// Format all of a note's fields and send them to the writer.
    ///
    /// - Parameter note: The note to be written.
    /// - Returns: The number of fields written.
    func putNote(_ note: Note) -> Int {
        writer.open()
        if note.hasTitle() {
            putField(note.getTitleAsField())
        }
        var i = 0
        while i < note.collection.dict.count {
            let def = note.collection.dict.getDef(i)
            if def != nil &&
                def!.fieldLabel.commonForm != LabelConstants.titleCommon &&
                def!.fieldLabel.commonForm != LabelConstants.bodyCommon {
                putField(note.getField(def: def!))
            }
            i += 1
        }
        if note.hasBody() {
            putField(note.getBodyAsField())
        }
        writer.close()
        return fieldsWritten
    }
    
    /// Write a field's label and value, along with the usual Notenik formatting.
    ///
    /// - Parameter field: The Note Field to be written.
    func putField(_ field: NoteField?) {
        if field != nil && field!.value.hasData {
            putFieldName(field!.def)
            putFieldValue(field!.value)
            fieldsWritten += 1
        }
    }
    
    /// Write the field label to the writer, along with any necessary preceding and following text.
    ///
    /// - Parameter def: The Field Definition for the field.
    func putFieldName(_ def: FieldDefinition) {
        if fieldsWritten > 0 {
            writer.endLine()
        }
        let proper = def.fieldLabel.properForm
        writer.write(proper)
        writer.write(": ")
        if def.fieldType == .longText || def.fieldType == .code {
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

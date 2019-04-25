//
//  DelimitedReader.swift
//  Notenik
//
//  Created by Herb Bowie on 4/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class to read a comma-delimited or tab-delimited file and return a dictionary and notes.
///
/// The file must have UTF-8 encoding. 
/// The first line of the file must contain column headings.
class DelimitedReader {
    
    var consumer:           RowConsumer
    
    var ok =                false
    var rowsReturned =      0
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    var bigString =         ""
    var lastChar:           Character = " "
    var endCount =          0
    var lineCount =         0
    var fieldCount =        0
    var charsInLine =       0
    
    var field =             ""
    var pendingSpaces =     ""
    
    var delimChar:          Character = " "
    var openQuote =         false
    var openQuoteChar:      Character = " "
    
    /// Initialize the class with a Row Consumer
    init (consumer: RowConsumer) {
        
        self.consumer = consumer
    }
    
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    func read(fileURL: URL) -> Int {
        rowsReturned = 0
        do {
            bigString = try String(contentsOf: fileURL, encoding: .utf8)
            scanString()
            ok = rowsReturned > 0
        } catch {
            Logger.shared.log(skip: false, indent: 0, level: .severe,
                              message: "Error reading Delimited Text File from \(fileURL)")
        }
        return rowsReturned
    }
    
    /// Parse the string into rows/lines and fields
    func scanString() {
        
        beginLine()
        beginField()
        
        for c in bigString {
            if openQuote {
                if c == openQuoteChar {
                    openQuote = false
                } else {
                    appendToField(c)
                }
            } else if c.isNewline {
                endCount += 1
                if lastChar.isNewline && c != lastChar && endCount <= 2 {
                    // Skip this character -- no action needed
                } else {
                    endLine()
                }
            } else if delimChar == " " && (c == "," || c == "\t") {
                delimChar = c
                endField()
            } else if c != " " && c == delimChar {
                endField()
            } else if field.count == 0 && (c == "'" || c == "\"") {
                openQuoteChar = c
                openQuote = true
            } else {
                appendToField(c)
            }
            lastChar = c
        }
        endLine()
    }

    /// Append the next character to the current field string, but
    /// ensure no leading or trailing spaces for the field.
    func appendToField(_ char: Character) {
        if char == " " {
            if field.count > 0 {
                pendingSpaces.append(char)
            }
        } else {
            if pendingSpaces.count > 0 {
                field.append(pendingSpaces)
                pendingSpaces = ""
            }
            field.append(char)
            charsInLine += 1
        }
    }
    
    /// End the field we've been building
    func endField() {
        if lineCount  == 0 {
            endHeaderField()
        } else {
            endDataField()
        }
        fieldCount += 1
        beginField()
    }
    
    /// End a header field, processing as a column heading
    func endHeaderField() {
        if field.count > 0 {
            labels.append(field)
        }
    }
    
    /// End a data field, processing as a row of data/note
    func endDataField() {
        if fieldCount < labels.count {
            let label = labels[fieldCount]
            consumer.consumeField(label: label, value: field)
            fields.append(field)
        }
    }
    
    /// Get ready to create a new field
    func beginField() {
        field = ""
        pendingSpaces = ""
    }
    
    /// End a line of input
    func endLine() {
        if charsInLine > 0 {
            endField()
            if lineCount > 0 {
                consumer.consumeRow(labels: labels, fields: fields)
            }
            lineCount += 1
        }
        beginLine()
    }
    
    /// Prepare to process a new line of input
    func beginLine() {
        lastChar = " "
        openQuote = false
        openQuoteChar = " "
        fieldCount = 0
        endCount = 0
        charsInLine = 0
        fields = []
    }
    
}

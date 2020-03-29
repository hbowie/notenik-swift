//
//  JSONWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 12/19/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class JSONWriter {
    
    /// Format with line breaks.
    var lineByLine = true
    
    /// The output writer to use.
    var writer: LineWriter = BigStringWriter()
    
    var startOfObject = true
    var indentLevel = 0
    var indent = ""
    var lineLength = 0
    var startOfLine = true
    var lineCount = 0
    
    /// Open the writer. This must always be performed once, before any writes occur.
    func open() {
        writer.open()
        indentLevel = 0
        indent = ""
        lineCount = 0
        lineLength = 0
    }
    
    /// Close the writer. This must always be done once, after all writes have occurred.
    func close() {
        writer.close()
    }
    
    /// Save the output to a file; this should follow the call to the close method.
    func save(destination: URL) -> Bool {
        do {
            try outputString.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "JSONWriter",
                              level: .error,
                              message: "Problem writing JSON to disk")
            return false
        }
        return true
    }
    
    /// Retrieve the output string after open, writing and close.
    var outputString: String {
        guard writer is BigStringWriter else { return "" }
        let big = writer as! BigStringWriter
        return big.bigString
    }
    
    /// Format an entire collection of notes as one big JSON object.
    func write(_ io: NotenikIO) {
        guard let collection = io.collection else { return }
        startObject()
        var (note, position) = io.firstNote()
        while note != nil {
            writeKey(note!.ID.identifier)
            startObject()
            let defs = collection.dict.list
            for def in defs {
                let value = note!.getFieldAsValue(label: def.fieldLabel.commonForm)
                if value.count > 0 {
                    writeKey(def.fieldLabel.properForm)
                    writeValue(value.value)
                }
            }
            endObject()
            (note, position) = io.nextNote(position)
        }
        endObject()
    }
    
    /// Write out the given note as a complete JSON object. 
    func writeNoteAsObject(_ note: Note) {
        let collection = note.collection
        let dict = collection.dict
        startObject()
        for def in dict.list {
            write(key: def.fieldLabel.properForm,
                  value: note.getFieldAsString(label: def.fieldLabel.commonForm))
        }
        endObject()
    }
    
    /// Write out the given note's body as a complete JSON object.
    func writeBodyAsObject(_ note: Note) {
        startObject()
        write(key: LabelConstants.body,
              value: note.getFieldAsString(label: LabelConstants.body))
        endObject()
    }
    
    /// Start the specification of an object.
    func startObject() {
        if lineByLine {
            startLine()
        }
        write("{")
        if lineByLine {
            endLine()
            increaseIndent()
        }
        startOfObject = true
    }
    
    /// End the specification of an object.
    func endObject() {
        if lineByLine {
            endLine()
            decreaseIndent()
            startLine()
        }
        write("}")
    }
    
    /// Write out a key and its associated value.
    func write(key: String, value: String) {
        writeKey(key)
        writeValue(value)
    }
    
    /// Write out a key identifying the field with its label.
    func writeKey(_ key: String) {
        if !startOfObject {
            write(",")
            if lineByLine {
                endLine()
            }
        }
        if !startOfLine {
            write(" ")
        }
        var keyCountTarget = 0
        if lineByLine {
            startLine()
            keyCountTarget = 13
        }
        write("\"\(key)\"")
        var keyCount = key.count
        repeat {
            write(" ")
            keyCount += 1
        } while keyCount < keyCountTarget
        write(":")
    }
    
    /// Write out the value associated with the preceding key.
    func writeValue(_ value: String) {
        if !startOfLine {
            write(" ")
        }
        write("\"\(encodedString(value))\"")
        startOfObject = false
    }
    
    /// Replace verboten characters with escaped equivalents.
    func encodedString(_ str: String) -> String {
        var v = str
        var i = v.startIndex
        for c in v {
            if c.isNewline {
                v.remove(at: i)
                v.insert("\\", at: i)
                i = v.index(after: i)
                v.insert("n", at: i)
            } else if c == "\t" {
                v.remove(at: i)
                v.insert("\\", at: i)
                i = v.index(after: i)
                v.insert("t", at: i)
            } else if c == "\"" || c == "\\" {
                v.insert("\\", at: i)
                i = v.index(after: i)
            }
            i = v.index(after: i)
        }
        return v
    }
    
    /// Bump up the indentation by 1 notch.
    func increaseIndent() {
        indentLevel += 1
        indent = String(repeating: " ", count: indentLevel * 2)
    }
    
    /// Bump the indentation back down by 1 notch.
    func decreaseIndent() {
        indentLevel -= 1
        indent = String(repeating: " ", count: indentLevel * 2)
    }
    
    /// Start a line by writing out the appropriate indentation.
    func startLine() {
        write(indent)
        startOfLine = true
    }
    
    /// Write some text to the current line.
    func write(_ str: String) {
        writer.write(str)
        lineLength += str.count
        startOfLine = false
    }
    
    /// End the current line.
    func endLine() {
        writer.endLine()
        lineLength = 0
        startOfLine = true
    }
    
}

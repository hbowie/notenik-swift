//
//  DelimitedWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 4/28/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class to write a comma-separated values or tab-delimited file
class DelimitedWriter {
    
    var destination: URL
    var format = NoteFormat.tabDelimited
    var sepChar: Character = "\t"
    var sepStr = "\t"
    var lineStarted = false
    
    var bigString = BigStringWriter()
    
    /// Must give us a destination url and the desired separator character upon initialization.
    init(destination: URL, format: NoteFormat) {
        self.format = format
        self.destination = destination
        switch format {
        case .commaSeparated:
            sepChar = ","
            sepStr = ","
        case .tabDelimited:
            sepChar = "\t"
            sepStr = "\t"
        default:
            break
        }
    }
    
    /// Open the writer for output.
    func open() {
        bigString = BigStringWriter()
        bigString.open()
        lineStarted = false
    }
    
    /// Write a single column's worth of data. The writer will enclose in quotation marks
    /// and encode embedded quotation marks as needed (with two quote chars representing one).
    func write(value: String) {
        var v = value
        if lineStarted {
            bigString.write(sepStr)
        }
        var quotesNeeded = false
        var i = v.startIndex
        for c in v {
            if c == sepChar {
                quotesNeeded = true
            } else if c.isNewline {
                quotesNeeded = true
            } else if c == "\"" {
                quotesNeeded = true
                v.insert("\"", at: i)
                i = v.index(after: i)
            }
            i = v.index(after: i)
        }
        if quotesNeeded {
            bigString.write("\"" + v + "\"")
        } else {
            bigString.write(v)
        }
        lineStarted = true
    }
    
    /// End a line to be written to the text file.
    func endLine() {
        bigString.endLine()
        lineStarted = false
    }
    
    /// Close the file and indicate any errors. Note that this is where all the
    /// disk i/o happens.
    func close() -> Bool {
        bigString.close()
        do {
            try bigString.bigString.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "DelimitedWriter",
                              level: .error,
                              message: "Problem writing delimited file to disk!")
            return false
        }
        return true
    }
    
}

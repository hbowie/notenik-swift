//
//  BigStringWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

class BigStringWriter: LineWriter, CustomStringConvertible {
    
    var bigString: String = ""
    
    var description: String {
        return bigString
    }
    
    /// Get ready to write some lines
    func open() {
        bigString = ""
    }
    
    /// Write the next line.
    func writeLine(_ line: String) {
        write(line)
        endLine()
    }
    
    /// Write some more text, without ending the line.
    func write(_ str: String) {
        bigString.append(str)
    }
    
    /// End the line.
    func endLine() {
        bigString.append("\n")
    }
    
    /// All done writing
    func close() {
        
    }
}

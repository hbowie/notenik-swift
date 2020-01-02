//
//  LineWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Something that can accept one line at a time
protocol LineWriter  {
    
    /// Get ready to write some lines
    func open()
    
    /// Write some more text, without ending the line.
    func write(_ str: String)
    
    /// Write the next line.
    func writeLine(_ line: String)
    
    /// End the line.
    func endLine()
    
    /// All done writing
    func close()
}

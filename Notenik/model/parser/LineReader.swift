//
//  LineReader.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Something that can return one line at a time
protocol LineReader  {
    
    /// Get ready to read some lines
    func open()
    
    /// Read the next line, returning nil at end of file
    func readLine() -> String?
    
    /// All done reading
    func close()
}

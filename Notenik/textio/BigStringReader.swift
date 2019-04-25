//
//  BigStringReader.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class BigStringReader: LineReader {
    
    var bigString : String = ""
    var index     : String.Index
    var lastIndex : String.Index
    var lastChar  : Character = " "
    var endCount  : Int = 0
    var lineCount : Int = 0
    var charCount : Int = 0
    
    init() {
        index = bigString.startIndex
        lastIndex = bigString.startIndex
    }
    
    convenience init(_ bigString : String) {
        self.init()
        set(bigString)
    }
    
    func set (_ bigString : String) {
        self.bigString = bigString
        index = bigString.startIndex
        lastIndex = bigString.startIndex
        lastChar = " "
        endCount = 0
        lineCount = 0
        charCount = 0
    }
    
    /// Get ready to read some lines
    func open() {
        index = bigString.startIndex
        lastIndex = bigString.startIndex
        lastChar = " "
        endCount = 0
        lineCount = 0
        charCount = 0
    }
    
    /// Read the next line, returning nil at end of file
    func readLine() -> String? {
        var startIndex = index
        var len = 0
        var line : String? = nil
        for c in bigString[startIndex...] {
            if c == "\n" || c == "\r" {
                endCount += 1
                if (lastChar == "\n" || lastChar == "\r") && c != lastChar && endCount <= 2 {
                    startIndex = bigString.index(startIndex, offsetBy: 1)
                } else if len == 0 {
                    line = ""
                    index = bigString.index(index, offsetBy: 1)
                    break
                } else {
                    line = String(bigString[startIndex...lastIndex])
                    index = bigString.index(index, offsetBy: 1)
                    break
                }
            } else {
                len += 1
                lastIndex = index
                endCount = 0
            }
            lastChar = c
            index = bigString.index(index, offsetBy: 1)
        }
        if line == nil && len > 0 {
            line = String(bigString[startIndex...lastIndex])
        }
        if line != nil {
            lineCount += 1
        }

        return line
    }
    
    /// All done reading
    func close() {
        index = bigString.startIndex
        lastChar = " "
    }
    
}

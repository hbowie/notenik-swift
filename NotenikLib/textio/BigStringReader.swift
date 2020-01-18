//
//  BigStringReader.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/18.
//  Copyright © 2018 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Breaks a string down into characters and lines
class BigStringReader: LineReader {
    
    /// The string to be read.
    var bigString:  String = ""
    
    /// An index pointing to the next position in the string to be read.
    var currIndex:  String.Index
    var nextIndex:  String.Index
    var lastIndex:  String.Index
    
    var currChar:   Character = " "
    var endOfLine = false
    var endOfFile = false
    
    var lastChar:   Character = " "
    
    var line       = ""
    var lineLength = 0
    var lineStartIndex: String.Index
    
    var lineCount : Int = 0
    var charCount : Int = 0
    
    /// Initialize with a blank initial value.
    init() {
        currIndex = bigString.startIndex
        nextIndex = bigString.startIndex
        lastIndex = bigString.startIndex
        lineStartIndex = bigString.startIndex
    }
    
    /// Initialize with a passed string. 
    convenience init(_ bigString: String) {
        self.init()
        set(bigString)
    }
    
    /// Attempt to initialize directly from a file URL.
    init?(fileURL: URL) {
        do {
            bigString = try String(contentsOf: fileURL, encoding: .utf8)
            currIndex = bigString.startIndex
            nextIndex = bigString.startIndex
            lastIndex = bigString.startIndex
            lineStartIndex = bigString.startIndex
        } catch {
            bigString = ""
            currIndex = bigString.startIndex
            nextIndex = bigString.startIndex
            lastIndex = bigString.startIndex
            lineStartIndex = bigString.startIndex
            return nil
        }
    }
    
    /// Set a new value for the string to be read, and position ourselves at the
    /// beginning of the string.
    func set (_ bigString : String) {
        self.bigString = bigString
        initVars()
    }
    
    /// Get ready to read some lines
    func open() {
        initVars()
    }
    
    func initVars() {
        currIndex = bigString.startIndex
        nextIndex = bigString.startIndex
        lastIndex = bigString.startIndex
        lineStartIndex = bigString.startIndex
        currChar = " "
        lastChar = " "
        lineCount = 0
        charCount = 0
        endOfLine = false
        endOfFile = false
    }
    
    /// Read the next line, returning nil at end of file
    func readLine() -> String? {
        
        guard !endOfFile else { return nil }
        
        lineCount += 1
        lineStartIndex = nextIndex
        lineLength = 0
        line = ""
        endOfLine = false
        
        while !endOfFile && !endOfLine {
            _ = nextChar()
            if !endOfLine {
                lineLength += 1
            }
        }
        
        if endOfFile {
            return nil
        } else if lineLength == 0 {
            return ""
        } else {
            line = String(bigString[lineStartIndex...lastIndex])
            return line
        }
        
    }
    
    /// Read the next character, setting a flag at the end of a line.
    func nextChar() -> Character {
        guard !endOfFile else { return " " }
        lastChar = currChar
        lastIndex = currIndex
        if nextIndex < bigString.endIndex {
            currChar = bigString[nextIndex]
            currIndex = nextIndex
            nextIndex = bigString.index(after: currIndex)
            if endOfLine {
                // If the last character returned indicated the end of a line,
                // then start a new one now.
                lineStartIndex = currIndex
                lineLength = 0
            }
            endOfLine = currChar.isNewline
        } else {
            endOfLine = true
            endOfFile = true
            currChar = " "
        }
        return currChar
    }
    
    /// When using nextChar to retrieve characters, this method can be used to retrieve
    /// the line just completed, after hitting end of line with nextChar.
    var lastLine: String {
        guard lineStartIndex < bigString.endIndex else { return "" }
        guard lineStartIndex < currIndex else { return "" }
        return String(bigString[lineStartIndex..<currIndex])
    }
    
    /// Return the remaining contents of the string, dropping any trailing spaces or newlines. 
    var remaining: String {
        var lastIndex = bigString.index(before: bigString.endIndex)
        while lastIndex > nextIndex &&
            (bigString[lastIndex].isWhitespace || bigString[lastIndex].isNewline) {
            lastIndex = bigString.index(before: lastIndex)
        }
        if nextIndex < lastIndex {
            return String(bigString[nextIndex...lastIndex])
        } else {
            endOfFile = true
            return ""
        }
    }
    
    /// All done reading
    func close() {
        currIndex = bigString.startIndex
        lastChar = " "
    }
    
}

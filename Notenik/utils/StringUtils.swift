//
//  StringUtils.swift
//  Notenik
//
//  Created by Herb Bowie on 11/28/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class StringUtils {
    
    private init() {
        
    }
    
    static let lowerChars = "a"..."z"
    static let upperChars = "A"..."Z"
    static let digits     = "0"..."9"
    
    /// Convert a string to its lowest common denominator, dropping white space and punctuation,
    /// converting all letters to lowercase, and dropping leading articles (a, an, the).
    ///
    /// - Parameter str: The string to be converted.
    ///
    /// - Returns: The lowest common denominator, allowing easy comparison,
    ///            and eliminating trivial differences.
    ///
    static func toCommon(_ str : String) -> String {
        let lower = str.lowercased()
        var common = ""
        for c in lower {
            if isDigit(c) || isAlpha(c) {
                common.append(c)
            } else if c == " " {
                if common == "a" || common == "the" || common == "an" {
                    common = ""
                }
            }
        }
        return common
    }
    
    /// Convert a string to a conventional, universal file name, changing spaces
    /// to dashes, removing any odd characters, making all letters lower-case, and
    /// converting white space to hyphens.
    ///
    /// - Parameter from: The file name to be converted.
    /// - Returns: The converted file name.
    static func toCommonFileName(_ from: String) -> String {
        var out = ""
        var whiteSpace = true
        var index = from.startIndex
        var nextIndex = from.startIndex
        for char in from {
            var nextChar: Character = " "
            if index < from.endIndex {
                nextIndex = from.index(after: index)
                if nextIndex < from.endIndex {
                    nextChar = from[nextIndex]
                }
            }
            if isAlpha(char) {
                out.append(char.lowercased())
                whiteSpace = false
            } else if isDigit(char) {
                out.append(char)
                whiteSpace = false
            } else if char == "." {
                if nextIndex >= from.endIndex || nextChar != " " {
                    out.append(char)
                    whiteSpace = false
                }
            } else if isWhitespace(char) || char == "_" || char == "/" || char == "-" {
                if !whiteSpace && nextIndex < from.endIndex {
                    out.append("-")
                    whiteSpace = true
                }
            }
            index = from.index(after: index)
        }
        return out
    }
    
    /// Scan for an link starting with http:// or https:// and then, if found,
    /// surround the URL with anchor start and end tags, with the href value
    /// pointing to the URL that was found. Leave any preceding or trailing
    /// characters in place. 
    static func convertLinks(_ from: String) -> String {
        var out = ""
        var index = from.startIndex
        var priorChar: Character = " "
        var priorIndex = from.startIndex
        var linkStartFound = false
        var linkStartIndex = from.startIndex
        var linkEndFound = false
        var linkEndIndex = from.endIndex
        while index < from.endIndex {
            let char = from[index]
            if !linkStartFound && (StringUtils.strEqual(str: from, index: index, str2: "http://") || StringUtils.strEqual(str: from, index: index, str2: "https://")) {
                linkStartFound = true
                linkStartIndex = index
            } else if linkStartFound && !linkEndFound && (char.isWhitespace || char == "<") {
                linkEndFound = true
                if priorChar == "." {
                    linkEndIndex = priorIndex
                } else {
                    linkEndIndex = index
                }
            } else if !linkStartFound {
                out.append(char)
            }
            priorChar = char
            priorIndex = index
            index = from.index(after: index)
        }
        if linkStartFound {
            if !linkEndFound && priorChar == "." {
                linkEndIndex = priorIndex
            }
            let url = String(from[linkStartIndex..<linkEndIndex])
            var postURL = ""
            if linkEndIndex < from.endIndex {
                postURL = String(from[linkEndIndex..<from.endIndex])
            }
            out.append("<a href=\"" + url + "\" target=\"ref\">")
            out.append(url)
            out.append("</a>")
            out.append(postURL)
        }
        return out
    }
    
    /// Remove punctuation from the string, replacing with spaces,
    /// but don't allow consecutive or trailing spaces.
    ///
    /// - Parameter from: The string to be purified.
    /// - Returns: The purified string.
    ///
    static func purifyPunctuation(_ from: String) -> String {
        var out = ""
        
        var pendingSpaces = 0
        for char in from {
            if char.isWhitespace || char.isPunctuation {
                pendingSpaces += 1
            } else {
                if pendingSpaces > 0 {
                    out.append(" ")
                    pendingSpaces = 0
                }
                out.append(char)
            }

        }
        return out
    }
    
    static func truncateOrPad(_ from: String, toLength: Int, keepOnRight: Bool = false) -> String {
        var out = ""
        if toLength == from.count {
            return from
        } else if toLength < from.count {
            if keepOnRight {
                return String(from.suffix(toLength))
            } else {
                return String(from.prefix(toLength))
            }
        } else {
            var zeroCount = toLength - from.count
            var zeros = ""
            while zeroCount > 0 {
                zeros.append("0")
                zeroCount -= 1
            }
            return zeros + from
        }
    }
    
    static func wordDemarcation(_ from: String, caseMods: [String], delimiter: String) -> String {
        var out = ""
        var demarcationPending = false
        var lastChar: Character = " "
        var positionInVariable = 0
        var positionInWord = 0
        for char in from {
            if char.isWhitespace || char.isPunctuation {
                demarcationPending = true
            } else {
                
                if positionInVariable > 0 && char.isUppercase && !lastChar.isUppercase {
                    demarcationPending = true
                }
                
                if demarcationPending {
                    out.append(delimiter)
                    positionInWord = 0
                    demarcationPending = false
                }
                
                var caseModsIndex = 2
                if positionInVariable == 0 {
                    caseModsIndex = 0
                } else if positionInWord == 0 {
                    caseModsIndex = 1
                }
                
                if caseMods[caseModsIndex] == "u" {
                    out.append(char.uppercased())
                } else if caseMods[caseModsIndex] == "l" {
                    out.append(char.lowercased())
                } else {
                    out.append(char)
                }
                
                lastChar = char
                positionInWord += 1
                positionInVariable += 1
                
            }
        }
        return out
    }
    
    static func underscoresForSpaces(_ from: String) -> String {
        var out = ""
        var pendingSpaces = 0
        for char in from {
            if char.isWhitespace || char == "_" {
                pendingSpaces += 1
            } else {
                if pendingSpaces > 0 {
                    if out.count > 0 {
                        out.append("_")
                    }
                    pendingSpaces = 0
                }
                out.append(char)
            }
        }
        return out
    }
    
    /// See if the next few characters in the first string are equal to
    /// the entire contents of the second string.
    ///
    /// - Parameters:
    ///   - str: The string being indexed.
    ///   - index: An index into the first string.
    ///   - str2: The second string.
    /// - Returns: True if equal, false otherwise.
    static func strEqual(str: String, index: String.Index, str2: String) -> Bool {
        guard str[index] == str2[str2.startIndex] else { return false }
        var strIndex = str.index(index, offsetBy: 1)
        var str2Index = str2.index(str2.startIndex, offsetBy: 1)
        while strIndex < str.endIndex && str2Index < str2.endIndex {
            if str[strIndex] != str2[str2Index] {
                return false
            }
            strIndex = str.index(strIndex, offsetBy: 1)
            str2Index = str2.index(str2Index, offsetBy: 1)
        }
        if str2Index < str2.endIndex {
            return false
        } else {
            return true
        }
    }
    
    /// Extract the beginning of a long piece of text, trying to end with
    /// a complete sentence. 
    static func summarize(_ str: String, max: Int = 250) -> String {
        guard str.count > max else { return str }
        var sentenceCount = 0
        var index = str.startIndex
        var lastSentenceEnd = str.startIndex
        var lastSpace = str.startIndex
        var i = 0
        while i < max {
            var nextChar: Character = " "
            if i < (max - 1) {
                let nextIndex = str.index(after: index)
                nextChar = str[nextIndex]
            }
            if str[index] == "." && nextChar == " " {
                lastSentenceEnd = str.index(after: index)
                sentenceCount += 1
            } else if str[index] == " " {
                lastSpace = index
            }
            index = str.index(after: index)
            i += 1
        }
        if sentenceCount > 0 {
            return String(str[str.startIndex..<lastSentenceEnd])
        } else {
            return String(str[str.startIndex..<lastSpace]) + "...."
        }
    }
    
    // Take a String and make a readable file name (without path or extension) from it
    static func toReadableFilename(_ from: String) -> String {
        var str = from
        if str.hasPrefix("http://") {
            str.removeFirst(7)
        } else if str.hasPrefix("https://") {
            str.removeFirst(8)
        }
        var fileName = ""
        var i = 0
        var nextChar: Character = " "
        var lastOut: Character = " "
        var lastIn: Character = " "
        for c in str {
            
            if str.count > (i + 1) {
                nextChar = StringUtils.charAt(index: i + 1, str: str)
            } else {
                nextChar = " "
            }
            
            if fileName.count > 0 {
                lastOut = StringUtils.charAt(index: fileName.count - 1, str: fileName)
            }
            
            if StringUtils.isAlpha(c) {
                fileName.append(c)
            } else if StringUtils.isDigit(c) {
                fileName.append(c)
            } else if StringUtils.isWhitespace(c) && lastOut == " " {
                // Avoid consecutive spaces
            } else if c == ":" && lastIn == ":" {
                // Avoid consecutive colons
            } else if StringUtils.isWhitespace(c) {
                fileName.append(" ")
            } else if c == "_" || c == "-" {
                fileName.append(c)
            } else if c == "\\" || c == "(" || c == ")" || c == "[" || c == "]" || c == "{" || c == "}" {
                // Let's just drop some punctuation
            } else if c == "/" {
                if lastOut != " " {
                    fileName.append(" ")
                }
            } else if c == "." && (fileName.hasSuffix("vs") || fileName.hasSuffix("VS")) {
                // Drop the period on "vs."
            } else if c == "&" {
                if lastOut != " " {
                    fileName.append(" ")
                }
                fileName.append("and ")
            } else if fileName.count > 0 {
                if nextChar == " " && lastOut != " " {
                    fileName.append(" ")
                }
                fileName.append("-")
            }
            lastIn = c
            i += 1
        }
        
        if fileName.count > 0 {
            if fileName.hasSuffix("-") || fileName.hasSuffix(" ") {
                fileName.removeLast()
            }
            if fileName.hasSuffix(".com") || fileName.hasSuffix(".COM") {
                fileName.removeLast(4)
            }
        }
    
        return fileName
    }
    
    /// Increment a passed digit or letter to its next value.
    ///
    /// If the passed character is at the end of its range, then the first
    /// character in the range will be returned. For example, incrementing '9'
    /// returns zero, incrementing 'z' returns 'a', incrementing 'Z' returns 'A'
    static func increment(_ toInc : Character) -> Character {
        var found = false
        var nextChar : Character = toInc
        if isDigit(toInc) {
            nextChar = "0"
            for c in "0123456789" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        } else if isLower(toInc) {
            nextChar = "a"
            for c in "abcdefghijklmnopqrstuvwxyz" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        } else if isAlpha(toInc) {
            nextChar = "A"
            for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        }
        return nextChar
    }
    
    /// Change the leading character to lower case
    static func toLowerFirstChar(_ str: String) -> String {
        return str.prefix(1).lowercased() + str.dropFirst()
    }
    
    /// Change the leading character to upper case
    static func toUpperFirstChar(_ str: String) -> String {
        return str.prefix(1).uppercased() + str.dropFirst()
    }
    
    /// Is this character a digit in the range 0 - 9?
    static func isDigit(_ c : Character) -> Bool {
        return "0"..."9" ~= c
    }
    
    /// Is this character a normal alphabetic character?
    static func isAlpha(_ c : Character) -> Bool {
        return ("a"..."z" ~= c) || ("A"..."Z" ~= c)
    }
    
    /// Is this character a lower case letter?
    static func isLower(_ c : Character) -> Bool {
        return "a"..."z" ~= c
    }
    
    /// Is this character some form of white space?
    static func isWhitespace(_ c : Character) -> Bool {
        return c == " " || c == "\t" || c == "\n" || c == "\r"
    }
    
    /// Remove white spaces from front and back of string
    static func trim(_ inStr: String) -> String {
        return inStr.trimmingCharacters(in: .whitespaces)
    }
    
    /// Remove white space and Markdown heading characters from front and back of string
    static func trimHeading(_ inStr : String) -> String {
        var headingFound = false
        var start = inStr.startIndex
        var end = inStr.endIndex
        var index = inStr.startIndex
        for c in inStr {
            if c == " " || c == "#" {
                // Skip spaces and heading characters
            } else {
                if !headingFound {
                    headingFound = true
                    start = inStr.index(index, offsetBy: 0)
                }
                end = inStr.index(index, offsetBy: 0)
            }
            index = inStr.index(index, offsetBy: 1)
        }
        return String(inStr[start...end])
    }
    
    /// Return the character located at the given position within the passed string
    static func charAt (index: Int, str: String) -> Character {
        let s = str.index(str.startIndex, offsetBy: index)
        return charAt(index: s, str: str)
    }
    
    /// Return the character located at the given position within the passed string
    static func charAt (index : String.Index, str: String) -> Character {
        let substr = str[index...index]
        var char : Character = " "
        for c in substr {
            char = c
        }
        return char
    }
    
    /// Replace a character at the given index position
    static func replaceChar(i : Int, str : inout String, newChar : Character) {
        let index = str.index(str.startIndex, offsetBy: i)
        let indexNext = str.index(index, offsetBy: 1)
        let range = index..<indexNext
        let newString = String(newChar)
        str.replaceSubrange(range, with: newString)
    }
    
    static func contains(_ target : String, within: String) -> Bool {
        return within.range(of: target) != nil
    }
}

/// See if the next few characters in the first string are equal to
/// the entire contents of the second string.
///
/// - Parameters:
///   - str: The string being indexed.
///   - index: An index into the first string.
///   - str2: The second string.
/// - Returns: True if equal, false otherwise.
extension String {
    
    
    /// Determines whether the passed string is equal to the
    /// equivalent portion of this string, as indexed by the
    /// given index.
    ///
    /// - Parameters:
    ///   - index: An index pointing to a location within the string.
    ///   - str2: A second string to compare to a portion of this one.
    /// - Returns: True if the next several characters of this string match
    ///            the characters of the passed string; false if characters
    ///            don't match, or if the matching takes us beyond the end
    ///            of this string.
    ///
    func indexedEquals(index: String.Index, str2: String) -> Bool {
        guard self[index] == str2[str2.startIndex] else { return false }
        var strIndex = self.index(index, offsetBy: 1)
        var str2Index = str2.index(str2.startIndex, offsetBy: 1)
        while strIndex < self.endIndex && str2Index < str2.endIndex {
            if self[strIndex] != str2[str2Index] {
                return false
            }
            strIndex = self.index(strIndex, offsetBy: 1)
            str2Index = str2.index(str2Index, offsetBy: 1)
        }
        if str2Index < str2.endIndex {
            return false
        } else {
            return true
        }
    }
    
    /// Return the character at the given offset from the given index, or space.
    ///
    /// - Parameters:
    ///   - index: An index pointing to a position within the string.
    ///   - offsetBy: An offset from that index.
    /// - Returns: The character at the offset location, or a space, if the
    ///            offset plus the index takes us beyond the end of the string.
    ///
    func charAtOffset(index: String.Index, offsetBy: Int) -> Character {
        var ix = index
        var offset = offsetBy
        var char: Character = " "
        while ix < self.endIndex && offset > 0 {
            ix = self.index(after: ix)
            offset -= 1
        }
        if offset == 0 && ix < self.endIndex {
            char = self[ix]
        }
        
        return char
    }
}

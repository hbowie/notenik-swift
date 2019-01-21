//
//  StringUtils.swift
//  Notenik
//
//  Created by Herb Bowie on 11/28/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
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
    static func trim(_ inStr : String) -> String {
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
    static func charAt (index : Int, str: String) -> Character {
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

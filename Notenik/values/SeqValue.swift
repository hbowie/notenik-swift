//
//  SeqValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A String Value interpreted as a sequence number, or revision letter, or version number.
///
/// Such a value may contain letters and digits and one or more periods or hyphens or dollar signs.
class SeqValue : StringValue {
    
    var positionOfFirstDecimal = -1
    var positionOfLastDecimal = -1
    var padChar     : Character = " "
    var punctuation : Character = " "
    var positionsToLeftOfDecimal = 0
    var positionsToRightOfDecimal = 0
    var digits = false
    var letters = false
    var uppercase = true
    
    /// Set this sequence value to the provided string
    override func set (_ value : String) {
        
        super.set(value)
        
        positionOfFirstDecimal = -1
        positionOfLastDecimal = -1
        padChar = " "
        punctuation = " "
        positionsToLeftOfDecimal = 0
        positionsToRightOfDecimal = 0
        digits = false
        letters = false
        uppercase = true
        var newValue = ""
        
        for c in value {
            if c != "." && c != "-" && positionOfFirstDecimal < 0 {
                positionsToLeftOfDecimal += 1
            }
            if c == "0" && newValue.count == 0 {
                padChar = c
            } else if StringUtils.isWhitespace(c) {
                // Drop spaces and other white space
            } else if c == "$" {
                newValue.append(c)
            } else if c == "'" {
                newValue.append(c)
            } else if c == "_" {
                newValue.append(c)
            } else if c == "," {
                newValue.append(c)
            } else if StringUtils.isAlpha(c) {
                newValue.append(c)
                letters = true
                if StringUtils.isLower(c) {
                    uppercase = false
                }
            } else if StringUtils.isDigit(c) {
                newValue.append(c)
                digits = true
                if positionOfLastDecimal >= 0 {
                    positionsToRightOfDecimal += 1
                }
            } else if c == "." || c == "-" {
                if positionOfFirstDecimal < 0 {
                    if newValue.count == 0 {
                        newValue.append("0")
                    }
                    positionOfFirstDecimal = newValue.count
                    punctuation = c
                }
                positionOfLastDecimal = newValue.count
                positionsToRightOfDecimal = 0
                newValue.append(c)
            } // end character evaluation
        } // end for loop
        self.value = newValue
    } // end set function
    
    /// Increment the sequence value by 1
    func increment (onLeft: Bool) {

        // Determine where to begin incrementing
        var i = value.count - 1
        if onLeft && positionOfFirstDecimal >= 0 {
            i = positionOfFirstDecimal - 1
        }
        
        if hasData {
            
            var carryon = true
            var c: Character = " "
            
            // Keep incrementing as long as we have 1 to carry to the next column to the left
            while carryon {
                // Get the character to be incremented on this pass
                if i < 0 {
                    if digits {
                        c = "0"
                    } else {
                        c = " "
                    }
                    value.insert(c, at: value.startIndex)
                    i = 0
                    positionsToLeftOfDecimal += 1
                    if positionOfFirstDecimal >= 0 {
                        positionOfFirstDecimal += 1
                    }
                    if positionOfLastDecimal >= 0 {
                        positionOfLastDecimal += 1
                    }
                } else {
                    c = StringUtils.charAt(index: i, str: value)
                }
                
                // Now try to increment it
                let newChar = StringUtils.increment(c)
                if newChar == c {
                    carryon = false
                } else {
                    StringUtils.replaceChar(i: i, str: &value, newChar: newChar)
                    carryon = newChar < c
                }
                i -= 1
            } // end while carrying on
        } // if we have any data to increment
    } // end function increment
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return pad(leftChar: "0", leftNumber: 8, rightChar: "0", rightNumber: 4)
    }
    
    /// Returns a padded string.
    ///
    /// - Parameters:
    ///   - leftChar:    Character to use to pad out to the left of the decimal point.
    ///   - leftNumber:  Number of positions to pad to the left of the decimal point.
    ///   - rightChar:   Character to use to pad out to the right of the decimal point.
    ///   - rightNumber: Number of positions to pad to the right of the decimal point.
    /// - Returns: A string reflecting the desired padding characteristics.
    func pad(leftChar: String, leftNumber: Int, rightChar: String, rightNumber: Int) -> String {
        var padded = ""
        
        // Pad on the left
        var positionsToLeft = value.count
        if positionOfFirstDecimal >= 0 {
            positionsToLeft = positionOfFirstDecimal
        }
        while positionsToLeft < leftNumber {
            padded.append(leftChar)
            positionsToLeft += 1
        }
        
        // Add the original string
        padded.append(value)
        
        // Now add padding on the right
        var positionsToRight = 0
        if positionOfLastDecimal >= 0 {
            positionsToRight = value.count - positionOfLastDecimal - 1
        }
        if rightNumber > 0 {
            if positionOfLastDecimal < 0 {
                padded.append(".")
            }
            while positionsToRight < rightNumber {
                padded.append(rightChar)
                positionsToRight += 1
            }
        }
        return padded
    }
}

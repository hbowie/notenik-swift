//
//  LongTextValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A class to contain long strings of text, including multiple lines with line breaks.
///
/// Note that the resulting value will not be allowed to have blank lines at its start or its end.
class LongTextValue : StringValue {
    
    /// Number of blank lines encountered but not yet added to value
    var pendingBlankLines = 0
    
    
    /// Append an additional string to this value.
    ///
    /// - Parameter additional: An additional string to be appended to this value
    func append (_ additional : String) {
        addPendingBlankLines()
        value.append(additional)
    }
    
    /// Append the passed text, followed by a new line character.
    ///
    /// - Parameter line: An additonal string of text to be appended.
    func appendLine(_ line : String) {
        if line.count > 0 {
            addPendingBlankLines()
            value.append(line)
            value.append("\n")
        } else if value.count > 0 {
            pendingBlankLines += 1
        }
    }
    
    /// When something non-blank is encountered, add all the pending blank lines. 
    func addPendingBlankLines() {
        while pendingBlankLines > 0 {
            value.append("\n")
            pendingBlankLines -= 1
        }
    }
    
}


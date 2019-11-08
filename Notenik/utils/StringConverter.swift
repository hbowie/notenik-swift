//
//  StringConverter.swift
//  Notenik
//
//  Created by Herb Bowie on 6/10/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class StringConverter {
    
    var fromToList: [StringFromTo] = []
    
    init() {
        
    }
    
    func addHTML() {
        add(from: "\"",  to: "&quot;")
        add(from: "'",   to: "&apos;")
        add(from: "&",   to: "&amp;")
        add(from: "<",   to: "&lt;")
        add(from: ">",   to: "&gt;")
        add(from: "...", to: "&hellip;")
    }
    
    /// Add standard XML conversions to the from/to list.
    func addXML() {
        add(from: "\"",  to: "&quot;")
        add(from: "'",   to: "&apos;")
        add(from: "&",   to: "&amp;")
        add(from: "<",   to: "&lt;")
        add(from: ">",   to: "&gt;")
        add(from: "...", to: "&hellip;")
    }
    
    /// Add conversions of various html entities back to normal straight single
    /// quotes, since email clients often seem to have trouble with the entities. 
    func addEmailQuotes() {
        add(from: "&lsquo;", to: "'")
        add(from: "&rsquo;", to: "'")
        add(from: "&#8217;", to: "'")
        add(from: "&#x2019;", to: "'")
        add(from: "&#39;", to: "'")
    }
    
    /// Add conversions to eliminate HTML break tags. 
    func addNoBreaks() {
        add(from: "<br>", to: "")
        add(from: "<br/>", to: "")
        add(from: "<br />", to: "")
    }
    
    /// Add one from/to pair to the conversion list.
    func add(from: String, to: String) {
        let fromTo = StringFromTo(from: from, to: to)
        fromToList.append(fromTo)
    }
    
    /// Convert a string using the from/to list. 
    func convert(from: String) -> String {
        var to = ""
        var index = from.startIndex
        while index < from.endIndex {
            var inc = 1
            var i = 0
            var found = false
            while i < fromToList.count && !found {
                if strEqual(str: from, index: index, str2: fromToList[i].from) {
                    to.append(fromToList[i].to)
                    inc = fromToList[i].from.count
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                to.append(from[index])
            }
            index = from.index(index, offsetBy: inc)
        }
        return to
    }
    
    /// See if the next few characters in the first string are equal to
    /// the entire contents of the second string.
    ///
    /// - Parameters:
    ///   - str: The string being indexed.
    ///   - index: An index into the first string.
    ///   - str2: The second string.
    /// - Returns: True if equal, false otherwise.
    func strEqual(str: String, index: String.Index, str2: String) -> Bool {
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
        return (str2Index >= str2.endIndex)
    }
}

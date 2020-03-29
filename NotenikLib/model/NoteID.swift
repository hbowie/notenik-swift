//
//  NoteID.swift
//  Notenik
//
//  Created by Herb Bowie on 3/27/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The unique identifier for a Note.
class NoteID: CustomStringConvertible, Equatable, Comparable {
    
    var rule: NoteIDRule = .fromTitle
    var source = ""
    var identifier = ""
    
    /// Initialize without a starting value, then set the value later.
    init() {
        
    }
    
    /// Initialize using information from the Note.
    init(_ note: Note) {
        set(from: note)
    }
    
    var count: Int {
        return identifier.count
    }
    
    /// Return the ID. 
    var description: String {
        return identifier
    }
    
    /// Set the ID using information from the Note.
    func set(from note: Note) {
        rule = note.collection.idRule
        switch rule {
        case .fromDate:
            source = note.timestamp.value
        case .fromTitle:
            source = note.title.value
        }
        identifier = StringUtils.toCommon(source)
    }
    
    /// If we have a duplicate, then add a number to the end, and increment it,
    /// returning the modified value. 
    func increment() -> String {
        var char: Character = " "
        var number = 0
        var power = 1
        var index = source.endIndex
        var found = false
        repeat {
            index = source.index(before: index)
            char = source.charAtOffset(index: index, offsetBy: 0)
            if let digit = char.wholeNumberValue {
                number = number + (digit * power)
                power = power * 10
            } else if char.isWhitespace || char.isPunctuation {
                if number > 0 {
                    found = true
                }
            }
        } while index > source.startIndex && char.isNumber
        
        if found {
            number += 1
        } else {
            number = 1
        }
        
        var originalEnd = source.endIndex
        if found {
            originalEnd = index
        }
        let original = source[source.startIndex..<originalEnd]
        var modified = ""
        switch rule {
        case .fromDate:
            modified = "\(original)-\(number)"
        case .fromTitle:
            modified = "\(original) \(number)"
        }
        source = modified
        identifier = StringUtils.toCommon(source)
        return modified
    }
    
    func updateSource(note: Note) {
        switch rule {
        case .fromDate:
            _ = note.setTimestamp(source)
        case .fromTitle:
            _ = note.setTitle(source)
        }
    }
    
    func display() {
        print("NoteID Rule: \(rule), Source: \(source), ID: \(identifier)")
    }
    
    static func == (lhs: NoteID, rhs: NoteID) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    static func < (lhs: NoteID, rhs: NoteID) -> Bool {
        return lhs.identifier < rhs.identifier
    }
}

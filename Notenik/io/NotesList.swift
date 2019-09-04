//
//  NotesList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A simple list of Notes. 
class NotesList: Sequence {
    
    var list = [Note]()
    
    var count: Int {
        return list.count
    }
    
    subscript(index: Int) -> Note {
        get {
            return list[index]
        }
        set {
            list[index] = newValue
        }
    }
    
    /// Search the list to position the index at a matching entry, or the
    /// last entry with a lower key.
    ///
    /// - Parameter sortKey: The sort key we are trying to position.
    /// - Returns: A tuple containing the index position, and a boolean to indicate whether
    ///            an exact match was found. The index will either point at the first
    ///            exact match, or the first row greater than the desired key.
    func searchList(_ note: Note) -> (Int, Bool) {
        var index = 0
        var exactMatch = false
        var bottom = 0
        var top = list.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if note > list[top] {
                    index = top + 1
                } else if note == list[top] {
                    exactMatch = true
                    index = top
                } else if note == list[bottom] {
                    exactMatch = true
                    index = bottom
                } else if note > list[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if note == list[middle] {
                    exactMatch = true
                    done = true
                    index = middle
                } else if note > list[middle] {
                    bottom = middle + 1
                } else {
                    top = middle
                }
            }
        }
        while exactMatch && index > 0 && note == list[index - 1] {
            index -= 1
        }
        return (index, exactMatch)
    }
    
    func append(_ note: Note) {
        list.append(note)
    }
    
    func insert(_ note: Note, at: Int) {
        list.insert(note, at: at)
    }
    
    func remove(at: Int) {
        list.remove(at: at)
    }
    
    func sort() {
        list.sort()
    }
    
    func makeIterator() -> NotesList.Iterator {
        return Iterator(self)
    }
    
    class Iterator: IteratorProtocol {
        
        typealias Element = Note
        
        var list: NotesList!
        var index = 0
        
        init(_ list: NotesList) {
            self.list = list
        }
        
        func next() -> Note? {
            if index < 0 || index >= list.count {
                return nil
            } else {
                let currIndex = index
                index += 1
                return list[currIndex]
            }
        }
        
    }
}


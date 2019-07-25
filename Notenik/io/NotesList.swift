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
                return list[index]
                index += 1
            }
        }
        
    }
}


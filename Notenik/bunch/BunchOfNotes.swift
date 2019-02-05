//
//  BunchOfNotes.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

class BunchOfNotes {
    
    var collection = NoteCollection()
    var notesDict = [String : Note]()
    var notesList = [Note]()
    var notesTree = TagsTree()
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var count: Int {
        return notesList.count
    }
    
    /// Get or Set the NoteSortParm for this collection of notes.
    var sortParm: NoteSortParm {
        get {
            return collection.sortParm
        }
        set {
            collection.sortParm = newValue
            notesList.sort()
        }
    }
    
    init() {
        
    }
    
    convenience init(collection: NoteCollection) {
        self.init()
        self.collection = collection
    }
    
    /// Add a new Note to memory, so it can be accessed later
    ///
    /// - Parameter note: The note to be added, whether from a data store or from a user
    /// - Returns: True if the note was added to the collection, false if it could not be added.
    func add(note : Note) -> Bool {
        let noteID = note.noteID
        let existingNote = notesDict[noteID]
        if existingNote != nil {
            return false
        } else {
            notesDict[noteID] = note
            let (index, _) = searchList(note.sortKey)
            if index < 0 {
                notesList.insert(note, at: 0)
            } else if index >= notesList.count {
                 notesList.append(note)
            } else {
                notesList.insert(note, at: index + 1)
            }
            notesTree.add(note: note)
            return true
        }
    }
    
    /// Search the list to position the index at a matching entry, or the
    /// last entry with a lower key.
    ///
    /// - Parameter sortKey: The sort key we are trying to position.
    /// - Returns: A tuple containing the index position, and a boolean to indicate whether
    ///            an exact match was found.
    func searchList(_ sortKey : String) -> (Int, Bool) {
        var index = 0
        var exactMatch = false
        if notesList.count == 0 {
            index = -1
            exactMatch = false
        } else if sortKey < notesList[0].sortKey {
            index = -1
            exactMatch = false
        } else if sortKey > notesList[notesList.count - 1].sortKey {
            index = notesList.count - 1
            exactMatch = false
        } else {
            index = 0
            while sortKey > notesList[index].sortKey && index < notesList.count {
                index += 1
            }
            index -= 1
            if index < 0 || index >= notesList.count {
                exactMatch = false
            } else {
                exactMatch = sortKey == notesList[index].sortKey
            }
        }
        return (index, exactMatch)
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at index: Int) -> Note? {
        if index < 0 || index >= notesList.count {
            return nil
        } else {
            return notesList[index]
        }
    }
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (Note?, NotePosition) {
        if notesList.count == 0 {
            return (nil, NotePosition(index: -1))
        } else {
            return (notesList[0], NotePosition(index: 0))
        }
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (Note?, NotePosition) {
        if notesList.count == 0 {
            return (nil, NotePosition(index: -1))
        } else {
            let index = notesList.count - 1
            return (notesList[index], NotePosition(index: index))
        }
    }
    
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position : NotePosition) -> (Note?, NotePosition) {
        let nextIndex = position.index + 1
        if nextIndex >= notesList.count {
            return (nil, NotePosition(index: -1))
        } else {
            return (notesList[nextIndex], NotePosition(index: nextIndex))
        }
    }
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The index position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position : NotePosition) -> (Note?, NotePosition) {
        let priorIndex = position.index - 1
        if priorIndex < 0 || priorIndex >= notesList.count {
            return (nil, NotePosition(index: -1))
        } else {
            return (notesList[priorIndex], NotePosition(index: priorIndex))
        }
    }
    
    func close() {
        notesDict = [String : Note]()
        notesList = [Note]()
        notesTree = TagsTree()
    }
}

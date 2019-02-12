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
    var listIndex = 0
    
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
            var selectedNote: Note?
            (selectedNote, _) = getSelectedNote()
            collection.sortParm = newValue
            notesList.sort()
            if notesList.count == 0 {
                listIndex = -1
            } else if listIndex > 0 && selectedNote != nil {
                (listIndex, _) = searchList(selectedNote!.sortKey) 
            }
        }
    }
    
    init() {
        
    }
    
    /// Initialize with a Note Collection
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
                listIndex = 0
            } else if index >= notesList.count {
                listIndex = notesList.count
                notesList.append(note)
            } else {
                notesList.insert(note, at: index + 1)
                listIndex = index + 1
            }
            notesTree.add(note: note)
            return true
        }
    }
    
    /// Select the given note and return its index, if it can be found in the sorted list.
    ///
    /// - Parameter note: The note we're looking for.
    /// - Returns: The note as it was found in the list, along with its position.
    ///            If not found, return nil and -1. 
    func selectNote(_ note: Note) -> (Note?, NotePosition) {
        let (index, exact) = searchList(note.sortKey)
        if exact {
            listIndex = index
            return selectNote(at: index)
        } else {
            return (nil, NotePosition(index: -1))
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
            if index < 0 || index >= notesList.count {
                exactMatch = false
            } else {
                exactMatch = sortKey == notesList[index].sortKey
            }
        }
        return (index, exactMatch)
    }
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    func selectNote(at index: Int) -> (Note?, NotePosition) {
        if index < 0 {
            listIndex = 0
        } else if index >= notesList.count {
            listIndex = notesList.count - 1
        } else {
            listIndex = index
        }
        if listIndex < 0 || listIndex >= notesList.count {
            listIndex = -1
            return (nil, NotePosition(index: listIndex))
        } else {
            return (notesList[listIndex], NotePosition(index: listIndex))
        }
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
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then wrap around to the first note.
    func nextNote(_ position : NotePosition) -> (Note?, NotePosition) {
        let nextIndex = position.index + 1
        if nextIndex >= notesList.count {
            return firstNote()
        } else {
            listIndex = nextIndex
            return (notesList[listIndex], NotePosition(index: listIndex))
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
            return lastNote()
        } else {
            listIndex = priorIndex
            return (notesList[listIndex], NotePosition(index: listIndex))
        }
    }
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (Note?, NotePosition) {
        if notesList.count == 0 {
            listIndex = -1
            return (nil, NotePosition(index: listIndex))
        } else {
            listIndex = 0
            return (notesList[listIndex], NotePosition(index: listIndex))
        }
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (Note?, NotePosition) {
        if notesList.count == 0 {
            listIndex = -1
            return (nil, NotePosition(index: listIndex))
        } else {
            listIndex = notesList.count - 1
            return (notesList[listIndex], NotePosition(index: listIndex))
        }
    }
    
    /// Return the note currently pointed to by the current list index value.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (Note?, NotePosition) {
        if listIndex < 0 || listIndex >= notesList.count {
            return (nil, NotePosition(index: -1))
        } else {
            return (notesList[listIndex], NotePosition(index: listIndex))
        }
    }
    
    /// Close the currently open collection (if any).
    func close() {
        notesDict = [String : Note]()
        notesList = [Note]()
        notesTree = TagsTree()
    }
}

//
//  NotenikIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

protocol NotenikIO {
    
    /// The currently open collection, if any
    var collection: NoteCollection? { get }
    
    /// The position of the selected note, if any, in the current collection
    var position:   NotePosition? { get }
    
    /// An indicator of the status of the Collection: open or closed
    var collectionOpen: Bool { get }
    
    /// Get information about the provider.
    func getProvider() -> Provider
    
    /// Get the default realm.
    func getDefaultRealm() -> Realm
    

    /// Attempt to open the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened. 
    /// - Parameter path: The path identifying the collection within this
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    func openCollection(realm: Realm, collectionPath: String) -> NoteCollection?
    
    /// Attempt to initialize the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String) -> Bool
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    func addDefaultDefinitions()
    
    /// Open a New Collection
    func newCollection(collection: NoteCollection) -> Bool
    
    /// Close the currently collection, if one is open
    func closeCollection()
    
    /// Get or Set the NoteSortParm for this collection.
    var sortParm: NoteSortParm {
        get
        set 
    }
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
        get
    }
    
    /// Register modifications to the old note to make the new note.
    ///
    /// - Parameters:
    ///   - oldNote: The old version of the note.
    ///   - newNote: The new version of the note.
    /// - Returns: <#return value description#>
    func modNote(oldNote: Note, newNote: Note) -> (Note?, NotePosition)
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    func addNote(newNote: Note) -> (Note?, NotePosition)
    
    /// Delete the given note
    ///
    /// - Parameter oldNote: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    func deleteNote(_ oldNote: Note) -> Bool
    
    /// Write a note to its data store within its collection.
    ///
    /// - Parameter note: The Note to be saved.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    func selectNote(at index: Int) -> (Note?, NotePosition)
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at: Int) -> Note?
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID id: String) -> Note?
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (Note?, NotePosition)
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (Note?, NotePosition)
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position : NotePosition) -> (Note?, NotePosition)
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position: NotePosition) -> (Note?, NotePosition)
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    func positionOfNote(_ note: Note) -> NotePosition
    
    /// Return the note currently selected.
    ///
    /// If no note is selected, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (Note?, NotePosition)
    
    /// Delete the currently selected Note
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    func deleteSelectedNote() -> (Note?, NotePosition)
    
    /// Return the root of the Tags tree
    func getTagsNodeRoot() -> TagsNode
}

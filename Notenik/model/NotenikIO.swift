//
//  NotenikIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

protocol NotenikIO {
    
    var collection: NoteCollection? { get }
    
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
    func openCollection(realm : Realm, collectionPath : String) -> NoteCollection?
    
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
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at: Int) -> Note?
    
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
    func priorNote(_ position : NotePosition) -> (Note?, NotePosition)
    
    func getTagsNodeRoot() -> TagsNode
}

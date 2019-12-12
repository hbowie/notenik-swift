//
//  BunchIO.swift
//  Notenik
//
//  Created by Herb Bowie on 5/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A NotenikIO module that stores all information in memory, without any persistent
/// backing. Used by RealmIO.
class BunchIO: NotenikIO, RowConsumer  {
    
    var provider       : Provider = Provider()
    var realm          : Realm
    var collection     : NoteCollection?
    var collectionFullPath: String?
    var collectionOpen = false
    
    var reports: [MergeReport] = []
    var reportsFullPath: String? = nil
    
    var pickLists = ValuePickLists()
    
    var bunch          : BunchOfNotes?
    
    var notesList: NotesList {
        if bunch != nil {
            return bunch!.notesList
        } else {
            return NotesList()
        }
    }
    
    var notePosition   = NotePosition(index: -1)
    
    var notesImported  = 0
    var noteToImport:    Note?
    
    /// Default initialization
    init() {
        provider.providerType = .memory
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        realm.name = NSUserName()
        realm.path = NSHomeDirectory()
        closeCollection()
    }
    
    /// See what sort of path this might be.
    func checkPathType(path: String) -> NotenikPathType {
        return .hopeless
    }
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
        guard bunch != nil else { return 0 }
        return bunch!.count
    }
    
    /// The position of the selected note, if any, in the current collection
    var position:   NotePosition? {
        if !collectionOpen || collection == nil || bunch == nil {
            return nil
        } else {
            notePosition.index = bunch!.listIndex
            return notePosition
        }
    }
    
    /// Get or Set the NoteSortParm for the current collection.
    var sortParm: NoteSortParm {
        get {
            return collection!.sortParm
        }
        set {
            if newValue != collection!.sortParm {
                collection!.sortParm = newValue
                bunch!.sortParm = newValue
            }
        }
    }
    
    /// Should the list be in descending sequence?
    var sortDescending: Bool {
        get {
            return collection!.sortDescending
        }
        set {
            if newValue != collection!.sortDescending {
                collection!.sortDescending = newValue
                bunch!.sortDescending = newValue
            }
        }
    }
    
    /// Open a Collection to be used as an archive for another Collection. This will
    /// be a normal open, if the archive has already been created, or will create
    /// a new Collection, if the Archive is being accessed for the first time.
    ///
    /// - Parameters:
    ///   - primeIO: The I/O module for the primary collection.
    ///   - archivePath: The location of the archive collection.
    /// - Returns: The Archive Note Collection, if collection opened successfully.
    func openArchive(primeIO: NotenikIO, archivePath: String) -> NoteCollection? {
        
        let primeCollection = primeIO.collection!
        let primeRealm = primeCollection.realm
        var newOK = initCollection(realm: primeRealm, collectionPath: archivePath)
        guard newOK else { return nil }
        let archiveCollection = collection
        archiveCollection!.sortParm = primeCollection.sortParm
        archiveCollection!.dict = primeCollection.dict
        newOK = newCollection(collection: archiveCollection!)
        guard newOK else { return nil }
        return collection
    }
    
    /// Purge closed notes from the collection, optionally writing them
    /// to an archive collection.
    ///
    /// - Parameter archiveIO: An optional I/O module already set up
    ///                        for an archive collection.
    /// - Returns: The number of notes purged.
    func purgeClosed(archiveIO: NotenikIO?) -> Int {
        guard collection != nil && collectionOpen else { return 0 }
        guard let notes = bunch?.notesList else { return 0 }
        
        // Now look for closed notes
        var notesToDelete: [Note] = []
        for note in notes {
            if note.isDone {
                var okToDelete = true
                if archiveIO != nil {
                    let (archiveNote, _) = archiveIO!.addNote(newNote: note)
                    if archiveNote == nil {
                        okToDelete = false
                        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                          category: "BunchIO",
                                          level: .error,
                                          message: "Could not add note titled '\(note.title.value)' to archive")
                    }
                } // end of optional archive operation
                if okToDelete {
                    notesToDelete.append(note)
                }
            } // end if note is done
        } // end for each note in the collection
        
        // Now do the actual deletes
        for note in notesToDelete {
            let deleted = deleteNote(note)
            if !deleted {
                print ("Problems deleting note!")
            }
        }
        
        return notesToDelete.count
    }
    
    /// Open the collection.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    func openCollection(realm: Realm, collectionPath: String) -> NoteCollection? {
        
        let initOK = initCollection(realm: realm, collectionPath: collectionPath)
        guard initOK else { return nil }
        bunch = BunchOfNotes(collection: collection!)
        collectionOpen = true
        return collection
    }
    
    /// Initialize the collection.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String) -> Bool {
        closeCollection()
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Initializing Collection")
        self.realm = realm
        self.provider = realm.provider
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Realm:      " + realm.path)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "BunchIO",
                          level: .info,
                          message: "Collection: " + collectionPath)
        
        // Let's see if we have an actual path to a usable directory
        var collectionURL : URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: collectionPath)
        } else if collectionPath == "" || collectionPath == " " {
            collectionURL = URL(fileURLWithPath: realm.path)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(collectionPath)
        }
        collectionFullPath = collectionURL.path
        collection = NoteCollection(realm: realm)
        collection!.path = collectionPath
        let folderIndex = collectionURL.pathComponents.count - 1
        let parentIndex = folderIndex - 1
        let folder = collectionURL.pathComponents[folderIndex]
        let parent = collectionURL.pathComponents[parentIndex]
        collection!.title = parent + " " + folder
        
        return true
    }
    
    /// Open a New Collection.
    ///
    /// The passed collection should already have been initialized
    /// via a call to initCollection above.
    func newCollection(collection: NoteCollection) -> Bool {
        self.collection = collection
        bunch = BunchOfNotes(collection: collection)
        collectionOpen = true
        return true
    }
    
    /// Get information about the provider.
    func getProvider() -> Provider {
        return provider
    }
    
    /// Get the default realm.
    func getDefaultRealm() -> Realm {
        return realm
    }
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    func addDefaultDefinitions() {
        guard collection != nil else { return }
        let dict = collection!.dict
        let types = collection!.typeCatalog
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.title)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.tags)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.link)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.body)
    }
    
    /// Load the list of reports available for this collection.
    func loadReports() {
        // Nothing to do here. 
    }
    
    /// Import Notes from a CSV or tab-delimited file
    ///
    /// - Parameter fileURL: The URL of the file to be imported.
    /// - Returns: The number of notes imported.
    func importRows(importer: RowImporter, fileURL: URL) -> Int {
        notesImported = 0
        guard collection != nil && collectionOpen else { return 0 }
        importer.setContext(consumer: self, workspace: nil)
        noteToImport = Note(collection: collection!)
        _ = importer.read(fileURL: fileURL)
        return notesImported
    }
    
    /// Do something with the next field produced.
    ///
    /// - Parameters:
    ///   - label: A string containing the column heading for the field.
    ///   - value: The actual value for the field.
    func consumeField(label: String, value: String) {
        _ = noteToImport!.setField(label: label, value: value)
    }
    
    
    /// Do something with a completed row.
    ///
    /// - Parameters:
    ///   - labels: An array of column headings.
    ///   - fields: A corresponding array of field values.
    func consumeRow(labels: [String], fields: [String]) {
        let (newNote, _) = addNote(newNote: noteToImport!)
        if newNote != nil {
            notesImported += 1
        }
        noteToImport = Note(collection: collection!)
    }
    
    /// Register modifications to the old note to make the new note.
    ///
    /// - Parameters:
    ///   - oldNote: The old version of the note.
    ///   - newNote: The new version of the note.
    /// - Returns: The modified note and its position.
    func modNote(oldNote: Note, newNote: Note) -> (Note?, NotePosition) {
        let modOK = deleteNote(oldNote)
        guard modOK else { return (nil, NotePosition(index: -1)) }
        return addNote(newNote: newNote)
    }
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    func addNote(newNote: Note) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        guard newNote.hasTitle() else { return (nil, NotePosition(index: -1)) }
        
        let added = bunch!.add(note: newNote)
        guard added else { return (nil, NotePosition(index: -1)) }
        pickLists.registerNote(note: newNote)
        let (_, position) = bunch!.selectNote(newNote)
        return (newNote, position)
    }
    
    /// Delete the given note
    ///
    /// - Parameter noteToDelete: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    func deleteNote(_ noteToDelete: Note) -> Bool {
        guard collection != nil && collectionOpen else { return false }
        let deleted = bunch!.delete(note: noteToDelete)
        return deleted
    }
    
    /// Select the note at the given position in the sorted list.
    ///
    /// - Parameter index: An index value pointing to a position in the list.
    /// - Returns: A tuple containing the indicated note, along with its index position.
    ///            - If the list is empty, return nil and -1.
    ///            - If the index is too high, return the last note.
    ///            - If the index is too low, return the first note.
    func selectNote(at index: Int) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.selectNote(at: index)
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at index: Int) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(at: index)
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID id: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forID: id)
    }
    
    /// Get the existing note with the specified timestamp, if one exists.
    /// - Parameter stamp: The timestamp we are looking for.
    /// - Returns: The Note with this timestamp, if one exists; otherwise nil.
    func getNote(forTimestamp stamp: String) -> Note? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.getNote(forTimestamp: stamp)
    }
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.firstNote()
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.lastNote()
    }
    
    
    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position : NotePosition) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.nextNote(position)
    }
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The index position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position : NotePosition) -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.priorNote(position)
    }
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    func positionOfNote(_ note: Note) -> NotePosition {
        guard collection != nil && collectionOpen else { return NotePosition(index: -1) }
        let (_, position) = bunch!.selectNote(note)
        return position
    }
    
    /// Return the note currently selected.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.getSelectedNote()
    }
    
    /// Delete the currently selected Note
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    func deleteSelectedNote() -> (Note?, NotePosition) {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        
        // Make sure we have a selected note
        let (noteToDelete, oldPosition) = bunch!.getSelectedNote()
        guard noteToDelete != nil && oldPosition.index >= 0 else { return (nil, NotePosition(index: -1)) }
        
        let (priorNote, priorPosition) = bunch!.priorNote(oldPosition)
        var nextNote = priorNote
        var nextPosition = priorPosition
        
        let deleted = bunch!.delete(note: noteToDelete!)
        guard deleted else { return (nil, NotePosition(index: -1))}
        var positioned = false
        if priorNote != nil {
            (nextNote, nextPosition) = bunch!.nextNote(priorPosition)
            if nextNote != nil {
                positioned = true
            }
        }
        if !positioned {
            _ = bunch!.firstNote()
        }
        
        return (nextNote, nextPosition)
    }
    
    func getTagsNodeRoot() -> TagsNode? {
        guard collection != nil && collectionOpen else { return nil }
        return bunch!.notesTree.root
    }
    
    /// Create an iterator for the tags nodes.
    func makeTagsNodeIterator() -> TagsNodeIterator {
        return TagsNodeIterator(noteIO: self)
    }
    
    /// Close the current collection, if one is open.
    func closeCollection() {
        collection = nil
        collectionOpen = false
        if bunch != nil {
            bunch!.close()
        }
    }
    
    /// Save some of the collection info to make it persistent
    func persistCollectionInfo() {
        // Does nothing for this particular implementation of NotenikIO
    }
    
    /// Write a note to disk within its collection.
    ///
    /// - Parameter note: The Note to be saved to disk.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool {
        // Does nothing for this particular implementation of NotenikIO
        return false
    }
    
    /// Add the specified attachment to the given note.
    ///
    /// - Parameters:
    ///   - from: The location of the file to be attached.
    ///   - to: The Note to which the file is to be attached.
    ///   - with: The unique identifier for this attachment for this note.
    /// - Returns: True if attachment added successfully, false if any sort of failure.
    func addAttachment(from: URL, to: Note, with: String) -> Bool {
        return false
    }
    
    /// Reattach the attachments for this note to make sure they are attached
    /// to the new note.
    ///
    /// - Parameters:
    ///   - note1: The Note to which the files were previously attached.
    ///   - note2: The Note to wich the files should now be attached.
    /// - Returns: True if successful, false otherwise.
    func reattach(from: Note, to: Note) -> Bool {
        if from.attachments.count == 0 { return true}
        return false
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(attachmentName: AttachmentName) -> URL? {
        return getURLforAttachment(fileName: attachmentName.fullName)
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(fileName: String) -> URL? {
        return nil
    }
    
    /// Return a path to the storage location for attachments.
    func getAttachmentsLocation() -> String? {
        return nil
    }
}

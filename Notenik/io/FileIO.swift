//
//  FileIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

class FileIO : NotenikIO {

    
    let fileManager = FileManager.default
    
    var provider    : Provider = Provider()
    var realm       : Realm
    var collection  : NoteCollection
    var notesDict = [String : Note]()
    var notesList = [Note]()
    
    /// Default initialization
    init() {
        provider.providerType = .file
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        realm.name = NSUserName()
        realm.path = NSHomeDirectory()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = paths[0]
        print ("Documents Directory = " + docDir.absoluteString)
    }
    
    /// Get information about the provider.
    func getProvider() -> Provider {
        return provider
    }
    
    /// Get the default realm.
    func getDefaultRealm() -> Realm {
        return realm
    }
    
    /// Attempt to open the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: A NoteCollection object, if the collection was opened successfully;
    ///            otherwise nil.
    func openCollection(realm : Realm, collectionPath : String) -> NoteCollection? {
        
        // Initialization
        notesDict = [String : Note]()
        notesList = [Note]()
        var templateFound = false
        var infoFound = false
        Logger.shared.log(skip: true, indent: 0, level: .normal, message: "Opening Collection")
        self.realm = realm
        self.provider = realm.provider
        Logger.shared.log(skip: false, indent: 1, level: .normal, message: "Realm:      " + realm.path)
        Logger.shared.log(skip: false, indent: 1, level: .normal, message: "Collection: " + collectionPath)
        
        // Let's see if we have an actual path to a usable directory
        var collectionURL : URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: collectionPath)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(collectionPath)
        }
        let collectionFullPath = collectionURL.path
        if !fileManager.fileExists(atPath: collectionFullPath) {
            Logger.shared.log(skip: false, indent: 1, level: .moderate,
                              message: "Collection folder does not exist")
            return nil
        }
        if !collectionURL.hasDirectoryPath {
            Logger.shared.log(skip: false, indent: 1, level: .moderate,
                              message: "Collection path does not point to a directory")
            return nil
        }
        
        // Let's read the directory contents
        collection = NoteCollection(realm: realm)
        collection.path = collectionPath
        
        var notesRead = 0
        
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: collectionFullPath)
            
            // First pass through directory contents -- look for template and info files
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath, path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                if fileName.infofile {
                    print ("Apparent Info File found at \(itemPath)")
                    let infoCollection = NoteCollection(realm: realm)
                    infoCollection.path = collectionPath
                    let infoNote = readNote(collection: infoCollection, noteURL: itemURL)
                    if infoNote != nil {
                        print ("Note retrieved")
                        collection.title = infoNote!.title.value
                        let sortParmStr = infoNote!.getFieldAsString(label: LabelConstants.sortParmCommon)
                        print ("With Sort Parm of \(sortParmStr)")
                        if sortParmStr.count > 0 {
                            let sortParmInt = Int(sortParmStr)
                            if sortParmInt != nil {
                                let sortParm : NoteSortParm? = NoteSortParm(rawValue: sortParmInt!)
                                if sortParm != nil {
                                    collection.sortParm = sortParm!
                                    print ("Setting sort parm to \(sortParmStr)")
                                    infoFound = true
                                }
                            }
                        }
                    }
                    
                } else if fileName.template {
                    let templateNote = readNote(collection: collection, noteURL: itemURL)
                    if templateNote != nil && templateNote!.fields.count > 0 && collection.dict.count > 0 {
                        templateFound = true
                        collection.dict.lock()
                    }
                }
                if infoFound && templateFound {
                    break
                }
            }
            
            // Second pass through directory contents -- look for Notes
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath, path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                if FileUtils.isDir(itemFullPath) {
                    // print ("- Is a Directory")
                } else if fileName.readme {
                    // print ("- Is a Read me file")
                } else if fileName.infofile {
                    // print ("- Is an Info file")
                } else if fileName.dotfile {
                    // print ("- Is a Dot File")
                } else if fileName.template {
                    // print ("- Is a Template")
                } else if fileName.noteExt {
                    let note = readNote(collection: collection, noteURL: itemURL)
                    if note != nil && note!.hasTitle() {
                        let noteAdded = addNoteToMemory(note!)
                        if noteAdded {
                            notesRead += 1
                        } else {
                            Logger.shared.log(skip: false, indent: 1, level: .severe, message: "Note with title of \(note!.title) appears to be a duplicate and could not be accessed")
                        }
                    } else {
                        Logger.shared.log(skip: false, indent: 1, level: .concerning,
                                          message: "No title for Note read from \(itemURL)")
                    }
                } else {
                    // print ("- Does not have a valid note extension")
                }
                
            }
        } catch let error {
            Logger.shared.log (skip: false, indent: 1, level: .moderate,
                               message: "Failed reading contents of directory: \(error)")
            return nil
        }
        if (notesRead == 0 && !infoFound && !templateFound) {
            Logger.shared.log(skip: false, indent: 1, level: .concerning,
                              message: "This folder does not seem to contain a valid Collection")
            return nil
        } else {
            Logger.shared.log(skip: false, indent: 1, level: .normal,
                              message: "\(notesRead) Notes loaded for the Collection")
            return collection
        }
    }
    
    /// Read a note from disk.
    ///
    /// - Parameter noteURL: The complete URL pointing to the note file to be read.
    /// - Returns: A note composed from the contents of the indicated file,
    ///            or nil, if problems reading file.
    func readNote(collection : NoteCollection, noteURL : URL) -> Note? {
        do {
            let itemContents = try String(contentsOf: noteURL, encoding: .utf8)
            let lineReader = BigStringReader(itemContents)
            let parser = LineParser(collection: collection, lineReader: lineReader)
            let note = parser.getNote()
            return note
        } catch {
            Logger.shared.log(skip: false, indent: 1, level: .severe,
                              message: "Error reading Note from \(noteURL)")
            return nil
        }
    }
    
    /// Get or Set the NoteSortParm for this collection. 
    var sortParm: NoteSortParm {
        get {
            return collection.sortParm
        }
        set {
            collection.sortParm = newValue
            notesList.sort()
        }
    }
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
        return notesList.count
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at index: Int) -> Note? {
        if index < 0 || index >= notesCount {
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
    
    /// Add a new Note to memory, so it can be accessed later
    ///
    /// - Parameter note: The note to be added, whether from a data store or from a user
    /// - Returns: True if the note was added to the collection, false if it could not be added.
    func addNoteToMemory(_ note : Note) -> Bool {
        let noteID = note.noteID
        let existingNote = notesDict[noteID]
        if existingNote != nil {
            return false
        } else {
            notesDict[noteID] = note
            let (index, exactMatch) = searchList(note.sortKey)
            if index < 0 {
                notesList.insert(note, at: 0)
            } else if index >= notesList.count {
                notesList.append(note)
            } else {
                notesList.insert(note, at: index + 1)
            }
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
}

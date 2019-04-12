//
//  FileIO.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class FileIO : NotenikIO {


    let fileManager = FileManager.default
    
    var provider       : Provider = Provider()
    var realm          : Realm
    var collection     : NoteCollection?
    var collectionFullPath: String?
    var collectionOpen = false
    
    var bunch          : BunchOfNotes = BunchOfNotes()
    var templateFound  = false
    var infoFound      = false
    var notePosition   = NotePosition(index: -1)
    
    /// The position of the selected note, if any, in the current collection
    var position:   NotePosition? {
        if !collectionOpen || collection == nil {
            return nil
        } else {
            notePosition.index = bunch.listIndex
            return notePosition
        }
    }
    
    /// Default initialization
    init() {
        provider.providerType = .file
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        realm.name = NSUserName()
        realm.path = NSHomeDirectory()
        // let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // let docDir = paths[0]
        closeCollection()
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
    func openCollection(realm: Realm, collectionPath: String) -> NoteCollection? {
        
        let initOK = initCollection(realm: realm, collectionPath: collectionPath)
        guard initOK else { return nil }
        
        // Let's read the directory contents
        bunch = BunchOfNotes(collection: collection!)
        
        var notesRead = 0
        
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: collectionFullPath!)
            
            // First pass through directory contents -- look for template and info files
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                                       path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                if fileName.infofile {
                    let infoCollection = NoteCollection(realm: realm)
                    infoCollection.path = collectionPath
                    let infoNote = readNote(collection: infoCollection, noteURL: itemURL)
                    if infoNote != nil {
                        collection!.title = infoNote!.title.value
                        let sortParmStr = infoNote!.getFieldAsString(label: LabelConstants.sortParmCommon)
                        var nsp: NoteSortParm = sortParm
                        nsp.str = sortParmStr
                        sortParm = nsp
                        infoFound = true
                    }
                    
                } else if fileName.template {
                    let templateNote = readNote(collection: collection!, noteURL: itemURL)
                    if templateNote != nil && templateNote!.fields.count > 0 && collection!.dict.count > 0 {
                        templateFound = true
                        collection!.dict.lock()
                        collection!.preferredExt = fileName.extLower
                    }
                }
                if infoFound && templateFound {
                    break
                }
            }
            
            // Second pass through directory contents -- look for Notes
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                                       path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                if FileUtils.isDir(itemFullPath) {
                    // Skip directories
                } else if fileName.readme {
                    // Skip the readme file
                } else if fileName.infofile {
                    // Skip the info file
                } else if fileName.dotfile {
                    // Skip filenames starting with a period
                } else if fileName.template {
                    // Skip the template file
                } else if fileName.noteExt {
                    let note = readNote(collection: collection!, noteURL: itemURL)
                    if note != nil && note!.hasTitle() {
                        let noteAdded = bunch.add(note: note!)
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
            collectionOpen = true
            bunch.sortParm = collection!.sortParm
            return collection
        }
    }
    
    /// Attempt to initialize the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String) -> Bool {
        closeCollection()
        Logger.shared.log(skip: true, indent: 0, level: .normal, message: "Initializing Collection")
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
        collectionFullPath = collectionURL.path
        if !fileManager.fileExists(atPath: collectionFullPath!) {
            Logger.shared.log(skip: false, indent: 1, level: .moderate,
                              message: "Collection folder does not exist")
            return false
        }
        if !collectionURL.hasDirectoryPath {
            Logger.shared.log(skip: false, indent: 1, level: .moderate,
                              message: "Collection path does not point to a directory")
            return false
        }
        collection = NoteCollection(realm: realm)
        collection!.path = collectionPath
        let folderIndex = collectionURL.pathComponents.count - 1
        let parentIndex = folderIndex - 1
        let folder = collectionURL.pathComponents[folderIndex]
        let parent = collectionURL.pathComponents[parentIndex]
        collection!.title = parent + " " + folder
        
        return true
    }
    
    /// Add the default definitions to the Collection's dictionary:
    /// Title, Tags, Link and Body
    func addDefaultDefinitions() {
        guard collection != nil else { return }
        let dict = collection!.dict
        dict.addDef(LabelConstants.title)
        dict.addDef(LabelConstants.tags)
        dict.addDef(LabelConstants.link)
        dict.addDef(LabelConstants.body)
    }
    
    /// Open a New Collection.
    ///
    /// The passed collection should already have been initialized
    /// via a call to initCollection above.
    func newCollection(collection: NoteCollection) -> Bool {
        
        self.collection = collection
        
        var ok = false
        
        // Make sure we have a good folder
        let collectionURL = collection.collectionFullPathURL
        guard collectionURL != nil else { return false }
        if !fileManager.fileExists(atPath: collection.collectionFullPath) {
            Logger.shared.log(skip: false, indent: 1, level: .moderate,
                              message: "Collection folder does not exist")
            return false
        }
        
        ok = saveReadMe()
        guard ok else { return ok }
        
        ok = saveInfoFile()
        guard ok else { return ok }
        
        ok = saveTemplateFile()
        guard ok else { return ok }
        
        let firstNote = Note(collection: collection)
        _ = firstNote.setTitle("Notenik")
        _ = firstNote.setLink("https://notenik.net")
        _ = firstNote.setTags("Software.Groovy")
        _ = firstNote.setBody("A note-taking system cunningly devised by Herb Bowie of PowerSurge Publishing")
        
        bunch = BunchOfNotes(collection: collection)
        let added = bunch.add(note: firstNote)
        guard added else {
            Logger.shared.log(skip: false,
                              indent: 0,
                              level: .severe,
                              message: "Couldn't add first note to internal storage")
            return false
        }
        
        firstNote.makeFileNameFromTitle()
        collectionOpen = true
        ok = writeNote(firstNote)
        guard ok else {
            Logger.shared.log(skip: false,
                              indent: 0,
                              level: .severe,
                              message: "Couldn't write first note to disk!")
            collectionOpen = false
            return ok
        }
        
        collectionOpen = true
        bunch.sortParm = collection.sortParm
        
        return ok
    }
    
    /// Save a README file into the current collection
    func saveReadMe() -> Bool {
        var str = "This folder contains a collection of notes created by the Notenik application."
        str.append("\n\n")
        str.append("Learn more at https://Notenik.net")
        str.append("\n")
        let filePath = collection!.makeFilePath(fileName: "- README.txt")
        
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(skip: false,
                              indent: 0,
                              level: .severe,
                              message: "Problem writing README to disk!")
            return false
        }
        return true
    }
    
    /// Save the INFO file into the current collection
    func saveInfoFile() -> Bool {
        var str = "Title: " + collection!.title + "\n\n"
        str.append("Link: " + collection!.collectionFullPathURL!.absoluteString + "\n\n")
        str.append("Sort Parm: " + collection!.sortParm.str + "\n\n")
        let filePath = collection!.makeFilePath(fileName: "- INFO.nnk")
        
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(skip: false,
                              indent: 0,
                              level: .severe,
                              message: "Problem writing INFO file to disk!")
            return false
        }
        return true
    }
    
    func saveTemplateFile() -> Bool {
        let dict = collection!.dict
        var str = ""
        for def in dict.list {
            str.append(def.fieldLabel.properForm + ": \n\n")
        }
        let filePath = collection!.makeFilePath(fileName: "template." + collection!.preferredExt)
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(skip: false,
                              indent: 0,
                              level: .severe,
                              message: "Problem writing template file to disk!")
            return false
        }
        return true
    }
    
    /// Close the current collection, if one is open
    func closeCollection() {
        collection = nil
        collectionOpen = false
        bunch.close()
        templateFound = false
        infoFound = false
    }
    
    /// Add a new Note to the Collection
    ///
    /// - Parameter newNote: The Note to be added
    /// - Returns: The added Note and its position, if added successfully;
    ///            otherwise nil and -1.
    func addNote(newNote: Note) -> (Note?, NotePosition) {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        guard newNote.hasTitle() else { return (nil, NotePosition(index: -1)) }
        
        let added = bunch.add(note: newNote)
        guard added else { return (nil, NotePosition(index: -1)) }
        
        newNote.makeFileNameFromTitle()
        let written = writeNote(newNote)
        if !written {
            return (nil, NotePosition(index: -1))
        } else {
            let (_, position) = bunch.selectNote(newNote)
            return (newNote, position)
        }
    }
    
    /// Write a note to disk within its collection.
    ///
    /// - Parameter note: The Note to be saved to disk.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return false }
        guard note.hasFileName() else { return false }
        
        let writer = BigStringWriter()
        let maker = NoteLineMaker(writer: writer)
        let fieldsWritten = maker.putNote(note)
        if fieldsWritten == 0 {
            return false
        } else {
            let stringToSave = NSString(string: writer.bigString)
            do {
                try stringToSave.write(toFile: note.fullPath!, atomically: true, encoding: String.Encoding.utf8.rawValue)
            } catch {
                Logger.shared.log(skip: false,
                                  indent: 0,
                                  level: .severe,
                                  message: "Problem writing Note to disk at \(note.fullPath!)")
                return false
            }
        }
        return true
    }
    
    /// Read a note from disk.
    ///
    /// - Parameter noteURL: The complete URL pointing to the note file to be read.
    /// - Returns: A note composed from the contents of the indicated file,
    ///            or nil, if problems reading file.
    func readNote(collection: NoteCollection, noteURL: URL) -> Note? {
        do {
            let itemContents = try String(contentsOf: noteURL, encoding: .utf8)
            let lineReader = BigStringReader(itemContents)
            let parser = NoteLineParser(collection: collection, lineReader: lineReader)
            let note = parser.getNote()
            let fileName = noteURL.lastPathComponent
            if fileName.count > 0 {
                note.fileName = fileName
                if !note.hasTitle() {
                    let fileNameUtil = FileName(noteURL)
                    _ = note.setTitle(fileNameUtil.base) 
                }
            }
            return note
        } catch {
            Logger.shared.log(skip: false, indent: 1, level: .severe,
                              message: "Error reading Note from \(noteURL)")
            return nil
        }
    }
    
    /// Get or Set the NoteSortParm for the current collection.
    var sortParm: NoteSortParm {
        get {
            return collection!.sortParm
        }
        set {
            collection!.sortParm = newValue
            bunch.sortParm = newValue
        }
    }
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
      return bunch.count
    }
    
    /// Return the position of a given note.
    ///
    /// - Parameter note: The note to find.
    /// - Returns: A Note Position
    func positionOfNote(_ note: Note) -> NotePosition {
        guard collection != nil && collectionOpen else { return NotePosition(index: -1) }
        let (_, position) = bunch.selectNote(note)
        return position
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
        return bunch.selectNote(at: index)
    }
    
    /// Return the note at the specified position in the sorted list, if possible.
    ///
    /// - Parameter at: An index value pointing to a note in the list
    /// - Returns: Either the note at that position, or nil, if the index is out of range.
    func getNote(at index: Int) -> Note? {
        return bunch.getNote(at: index)
    }
    
    /// Get the existing note with the specified ID.
    ///
    /// - Parameter id: The ID we are looking for.
    /// - Returns: The Note with this key, if one exists; otherwise nil.
    func getNote(forID id: String) -> Note? {
        return bunch.getNote(forID: id)
    }
    
    /// Return the first note in the sorted list, along with its index position.
    ///
    /// If the list is empty, return a nil Note and an index position of -1.
    func firstNote() -> (Note?, NotePosition) {
        return bunch.firstNote()
    }
    
    /// Return the last note in the sorted list, along with its index position
    ///
    /// if the list is empty, return a nil Note and an index position of -1.
    func lastNote() -> (Note?, NotePosition) {
        return bunch.lastNote()
    }
    

    /// Return the next note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The position of the last note.
    /// - Returns: A tuple containing the next note, along with its index position.
    ///            If we're at the end of the list, then return a nil Note and an index of -1.
    func nextNote(_ position : NotePosition) -> (Note?, NotePosition) {
        return bunch.nextNote(position)
    }
    
    /// Return the prior note in the sorted list, along with its index position.
    ///
    /// - Parameter position: The index position of the last note accessed.
    /// - Returns: A tuple containing the prior note, along with its index position.
    ///            if we're outside the bounds of the list, then return a nil Note and an index of -1.
    func priorNote(_ position : NotePosition) -> (Note?, NotePosition) {
        return bunch.priorNote(position)
    }
    
    /// Return the note currently selected.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch.getSelectedNote()
    }
    
    /// Delete the currently selected Note
    ///
    /// - Returns: The new Note on which the collection should be positioned.
    func deleteSelectedNote() -> (Note?, NotePosition) {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        
        // Make sure we have a selected note
        let (noteToDelete, oldPosition) = bunch.getSelectedNote()
        guard noteToDelete != nil && oldPosition.index >= 0 else { return (nil, NotePosition(index: -1)) }
        
        let (priorNote, priorPosition) = bunch.priorNote(oldPosition)
        var nextNote = priorNote
        var nextPosition = priorPosition
 
        bunch.delete(note: noteToDelete!)
        var positioned = false
        if priorNote != nil {
            (nextNote, nextPosition) = bunch.nextNote(priorPosition)
            if nextNote != nil {
                positioned = true
            }
        }
        if !positioned {
            bunch.firstNote()
        }
        
        let notePath = noteToDelete!.fullPath
        if notePath != nil {
            do {
                try fileManager.removeItem(atPath: notePath!)
            } catch {
                Logger.shared.log(skip: true, indent: 0, level: .concerning,
                                  message: "Could not delete note file at '\(notePath)'")
            }
        }
        
        return (nextNote, nextPosition)
    }
    
    func getTagsNodeRoot() -> TagsNode {
        return bunch.notesTree.root
    }
    
}

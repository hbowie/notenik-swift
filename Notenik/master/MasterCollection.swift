//
//  MasterCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 4/29/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Class providing access to a Master Collection: A Collection of Collections
class MasterCollection {
    
    /// Provide a standard shared singleton instance
    static let shared = MasterCollection()
    
    // Shorthand references to System Objects
    let defaults =    UserDefaults.standard
    let fileManager = FileManager.default
    
    let masterURLKey    = "master-url"
    var masterURL:      URL?
    var masterIO:       FileIO?
    
    var collectionsAdded = 0
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        masterURL = defaults.url(forKey: masterURLKey)
        if masterURL != nil {
            masterIO = FileIO()
            let realm = masterIO!.getDefaultRealm()
            realm.path = ""
            let collection = masterIO!.openCollection(realm: realm, collectionPath: masterURL!.path)
            if collection != nil {
                collection!.master = true
                Logger.shared.log(skip: false, indent: 0, level: .normal, message: "Master Collection successfully opened: \(masterURL!.path)")
            }
        }
    }
    
    /// Create a new Master after user has specified the location
    func newMaster(newURL: URL) -> Bool {
        
        let initIO = FileIO()
        let realm = initIO.getDefaultRealm()
        realm.path = ""
        
        let initOK = initIO.initCollection(realm: realm, collectionPath: newURL.path)
        
        guard initOK else { return false }
        guard let collection = initIO.collection else { return false }
        
        let dict = collection.dict
        _ = dict.addDef(LabelConstants.title)
        _ = dict.addDef(LabelConstants.tags)
        _ = dict.addDef(LabelConstants.link)
        _ = dict.addDef(LabelConstants.seq)
        _ = dict.addDef(LabelConstants.body)
        collection.master = true
        masterIO = FileIO()
        let ok = masterIO!.newCollection(collection: collection)
        guard ok else {
            Logger.shared.log(skip: true, indent: 0, level: LogLevel.moderate,
                              message: "Problems initializing the new master collection at " + collection.collectionFullPath)
            return false
        }
        
        Logger.shared.log(skip: true, indent: 0, level: LogLevel.normal,
                          message: "New Master Collection successfully initialized at \(collection.collectionFullPath)")
        
        defaults.set(newURL, forKey: masterURLKey)
        
        return true
    }
    
    /// Scan the next directory for info files and/or for other directories
    func searchForCollections(within: URL) -> Int {
        guard masterIO != nil else { return -1 }
        collectionsAdded = 0
        scanFolder(folderPath: within.path)
        return collectionsAdded
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    func scanFolder(folderPath: String) {
        let folderURL = URL(fileURLWithPath: folderPath)
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: folderPath,
                                                       path2: itemPath)
                if itemPath == masterIO!.infoFileName {
                    let infoCollection = NoteCollection(realm: masterIO!.realm)
                    infoCollection.path = folderPath
                    let itemURL = URL(fileURLWithPath: itemFullPath)
                    let infoNote = masterIO!.readNote(collection: infoCollection, noteURL: itemURL)
                    if infoNote != nil {
                        registerCollection(title: infoNote!.title.value, collectionURL: folderURL)
                    }
                } else if FileUtils.isDir(itemFullPath) {
                    scanFolder(folderPath: itemFullPath)
                }
            }
        } catch {
            Logger.shared.log (skip: false, indent: 0, level: .moderate,
                               message: "Failed reading contents of folder at '\(folderPath)'")
        }
    }
    
    /// Update the Master with the latest info about a Collection
    func registerCollection(title: String, collectionURL: URL) {
        guard let io = masterIO else { return }
        guard collectionURL != io.collection?.collectionFullPathURL else { return }
        let link = collectionURL.absoluteString
        var found = false
        var i = 0
        var masterNote: Note?
        while i < io.notesCount && !found {
            masterNote = io.getNote(at: i)
            if link == masterNote!.link.value {
                found = true
            } else {
                i += 1
            }
        }
        
        if found {
            if masterNote!.title.value != title {
                let modMaster = masterNote!.copy() as! Note
                modMaster.setTitle(title)
                io.modNote(oldNote: masterNote!, newNote: modMaster)
            }
        } else {
            let masterNote = Note(collection: io.collection!)
            masterNote.setTitle(title)
            masterNote.setLink(collectionURL.absoluteString)
            let (note, _) = io.addNote(newNote: masterNote)
            if note == nil {
                Logger.shared.log(skip: false, indent: 0, level: .concerning, message: "Unable to add a new Collection to the Master collection")
            } else {
                collectionsAdded += 1
            }
        }
    }
    
}

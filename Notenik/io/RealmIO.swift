//
//  RealmIO.swift
//  Notenik
//
//  Created by Herb Bowie on 5/16/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class RealmIO {
    
    /// Provide a standard shared singleton instance
    static let shared = RealmIO()
    
    let fileManager = FileManager.default
    
    let foldersToSkip = Set(["cgi-bin", "core", "css", "downloads", "files", "fonts", "images", "includes", "javascript", "js", "lib", "modules", "reports", "scripts", "themes", "wp-admin", "wp-content", "wp-includes"])
    
    /// Open a realm, looking for its collections
    func openRealm(path: String) -> NotenikIO? {
        let provider = Provider()
        let realm = Realm(provider: provider)
        realm.path = path
        realm.name = path
        
        let io = BunchIO()
        let collection = io.openCollection(realm: realm, collectionPath: "")
        
        if collection != nil {
            scanFolder(folderPath: path, realm: realm, io: io)
            collection!.readOnly = true
            collection!.isRealmCollection = true
        } else {
            Logger.shared.log(skip: false, indent: 2, level: .moderate,
                              message: "Unable to the realm collection for \(path)")
        }
        
        if collection != nil && io.notesCount > 0 {
            return io
        } else {
            Logger.shared.log(skip: false, indent: 2, level: .moderate,
                              message: "No Notenik Collections found within \(path)")
            return nil
        }
    }
    
    /// Scan folders recursively looking for signs that they are Notenik Collections
    func scanFolder(folderPath: String, realm: Realm, io: NotenikIO) {
        let folderURL = URL(fileURLWithPath: folderPath)
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: folderPath)
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: folderPath,
                                                       path2: itemPath)
                if itemPath == FileIO.infoFileName {
                    let infoIO = FileIO()
                    let initOK = infoIO.initCollection(realm: realm, collectionPath: folderPath)
                    if initOK {
                        let infoCollection = infoIO.collection
                        let infoURL = URL(fileURLWithPath: itemFullPath)
                        if infoCollection != nil {
                            let infoNote = infoIO.readNote(collection: infoCollection!, noteURL: infoURL)
                            if infoNote != nil {
                                let realmNote = Note(collection: io.collection!)
                                let titleOK = realmNote.setTitle(infoNote!.title.value)
                                if !titleOK {
                                    Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                                      message: "Unable to find a Title for Collection located at \(folderPath)")
                                }
                                let linkOK = realmNote.setLink(folderURL.absoluteString)
                                if !linkOK {
                                    Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                                      message: "Unable to record a Link for Collection located at \(folderPath)")
                                }
                                let (addedNote, position) = io.addNote(newNote: realmNote)
                                if addedNote == nil {
                                    Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                                      message: "Unable to record the Collection located at \(folderPath)")
                                }
                            } else {
                                Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                                  message: "Couldn't read the INFO file for Collection located at \(folderPath)")
                            }
                        } else {
                            Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                              message: "Unable to initialize Collection located at \(folderPath)")
                        }
                    } else {
                        Logger.shared.log(skip: false, indent: 2, level: .moderate,
                                          message: "Unable to initialize Collection located at \(folderPath)")
                    }
                } else if itemPath.hasPrefix(".") {
                    // Ignore invisible files
                } else if itemPath.hasSuffix(".app") {
                    // Ignore application bundles
                } else if itemPath.hasSuffix(".dmg") {
                    // Ignore disk image bundles
                } else if FileUtils.isDir(itemFullPath) {
                    if !foldersToSkip.contains(itemPath) {
                        scanFolder(folderPath: itemFullPath, realm: realm, io: io)
                    }
                }
            }
        } catch {
            Logger.shared.log (skip: false, indent: 0, level: .moderate,
                               message: "Failed reading contents of folder at '\(folderPath)'")
        }
    }
}

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

/// Retrieve and save Notes from and to files stored locally.
class FileIO: NotenikIO, RowConsumer {
    
    let filesFolderName     = "files"
    let reportsFolderName   = "reports"
    let scriptExt           = ".tcz"
    let templateID          = "template"
    
    let fileManager = FileManager.default
    
    var attachments: [String]?
    
    static let infoFileName = "- INFO.nnk"
    
    var provider       : Provider = Provider()
    var realm          : Realm
    var collection     : NoteCollection?
    var collectionFullPath: String?
    var collectionOpen = false
    
    var reports: [MergeReport] = []
    
    var reportsFullPath: String? {
        if collectionFullPath == nil {
            return nil
        } else {
            return FileUtils.joinPaths(path1: collectionFullPath!, path2: reportsFolderName)
        }
    }
    
    var pickLists = ValuePickLists()
    
    var bunch          : BunchOfNotes?
    var templateFound  = false
    var infoFound      = false
    var notePosition   = NotePosition(index: -1)
    
    var notesImported  = 0
    var noteToImport:    Note?
    
    var notesList: NotesList {
        if bunch != nil {
            return bunch!.notesList
        } else {
            return NotesList()
        }
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
    
    /// Default initialization
    init() {
        provider.providerType = .file
        realm = Realm(provider: provider)
        collection = NoteCollection(realm: realm)
        pickLists.statusConfig = collection!.statusConfig
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
    
    /// See what sort of path this might be.
    func checkPathType(path: String) -> NotenikPathType {
        
        guard FileUtils.isDir(path) else {
            logInfo("Notenik cannot do anything with this path: \(path)")
            return .hopeless
        }
        
        let infoPath = FileUtils.joinPaths(path1: path, path2: FileIO.infoFileName)
        if fileManager.fileExists(atPath: infoPath)
            && fileManager.isReadableFile(atPath: infoPath) {
            return .existing
        }
        
        var contents: [String] = []
        do {
            contents = try fileManager.contentsOfDirectory(atPath: path)
        } catch {
            logInfo("Problems reading contents of folder at \(path)")
            return .hopeless
        }

        if contents.count == 0 {
            logInfo("Empty folder found at \(path)")
            return .empty
        }
        
        var foldersFound = 0
        var notesFound = 0
        for itemPath in contents {
            let itemFullPath = FileUtils.joinPaths(path1: path,
                                                   path2: itemPath)
            let fileName = FileName(itemFullPath)
            if FileUtils.isDir(itemFullPath) {
                if itemPath == reportsFolderName {
                    // Skip this type of folder
                } else {
                    foldersFound += 1
                }
            } else if fileName.readme {
                // Skip the readme file
            } else if fileName.infofile {
                // Skip the info file
            } else if fileName.dotfile {
                // Skip filenames starting with a period
            } else if fileName.template {
                // Skip the template file
            } else if fileName.licenseFile {
                // Skip a LICENSE file
            } else if fileName.collectionParms {
                // Skip a Collection Parms file
            } else if fileName.noteExt {
                notesFound += 1
            } else {
                // print ("- Does not have a valid note extension")
            }
        }
        if notesFound > 0 {
            return .existing
        } else if foldersFound > 0 {
            return .realm
        } else {
            logInfo("Empty folder found at \(path)")
            return .empty
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
        
        // See if the archive already exists
        let primeCollection = primeIO.collection!
        let primeRealm = primeCollection.realm
        var archiveCollection = openCollection(realm: primeRealm, collectionPath: archivePath)
        guard archiveCollection == nil else { return archiveCollection }
        
        // If not, then create a new one
        var newOK = initCollection(realm: primeRealm, collectionPath: archivePath)
        guard newOK else { return nil }
        archiveCollection = collection
        archiveCollection!.sortParm = primeCollection.sortParm
        archiveCollection!.sortDescending = primeCollection.sortDescending
        archiveCollection!.dict = primeCollection.dict
        archiveCollection!.preferredExt = primeCollection.preferredExt
        newOK = newCollection(collection: archiveCollection!)
        guard newOK else { return nil }
        return collection
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
        
        loadAttachments()
        
        var notesRead = 0
        
        _ = loadInfoFile(realm: realm,
                                    collectionPath: collectionPath,
                                    itemPath: FileIO.infoFileName)
        
        var templateNote = loadTemplateFile(realm: realm,
                                            collectionPath: collectionPath,
                                            itemPath: "template.txt")
        if templateNote == nil {
            templateNote = loadTemplateFile(realm: realm,
                                            collectionPath: collectionPath,
                                            itemPath: "template.md")
        }
        
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: collectionFullPath!)
            
            // First pass through directory contents -- look for template and info files
            if !infoFound || !templateFound {
                scanDirForSpecialFiles(realm: realm,
                                       collectionPath: collectionPath,
                                       dirContents: dirContents)
            }
            
            // Second pass through directory contents -- look for Notes
            pickLists.statusConfig = collection!.statusConfig
            for itemPath in dirContents {
                let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                                       path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                if FileUtils.isDir(itemFullPath) {
                    if itemPath == reportsFolderName {
                        loadReports()
                    }
                } else if fileName.readme {
                    // Skip the readme file
                } else if fileName.infofile {
                    // Skip the info file
                } else if fileName.dotfile {
                    // Skip filenames starting with a period
                } else if fileName.template {
                    // Skip the template file
                } else if fileName.licenseFile {
                    // Skip a LICENSE file
                } else if fileName.collectionParms {
                    // Skip a Collection Parms file
                } else if fileName.noteExt {
                    let note = readNote(collection: collection!, noteURL: itemURL)
                    if note != nil && note!.hasTitle() {
                        addAttachments(to: note!)
                        pickLists.registerNote(note: note!)
                        let noteAdded = bunch!.add(note: note!)
                        if noteAdded {
                            notesRead += 1
                        } else {
                            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                              category: "FileIO",
                                              level: .error,
                                              message: "Note titled '\(note!.title.value)' appears to be a duplicate and could not be accessed")
                        }
                    } else {
                        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                          category: "FileIO",
                                          level: .error,
                                          message: "No title for Note read from \(itemURL)")
                    }
                } else {
                    // print ("- Does not have a valid note extension")
                }
                
            }
        } catch let error {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Failed reading contents of directory: \(error)")
            return nil
        }
        if (notesRead == 0 && !infoFound && !templateFound) {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "This folder does not seem to contain a valid Collection")
            return nil
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .info,
                              message: "\(notesRead) Notes loaded for the Collection")
            collectionOpen = true
            bunch!.sortParm = collection!.sortParm
            bunch!.sortDescending = collection!.sortDescending
            if pickLists.tagsPickList.values.count > 0 {
                AppPrefs.shared.pickLists = pickLists
            }
            if !infoFound {
                _ = saveInfoFile()
            }
            return collection
        }
    }
    
    /// Scan the directory list for an info and template file.
    func scanDirForSpecialFiles(realm: Realm, collectionPath: String, dirContents: [String]) {
        // First pass through directory contents -- look for template and info files
        for itemPath in dirContents {
            let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                                   path2: itemPath)
            let fileName = FileName(itemFullPath)
            if fileName.infofile && !infoFound {
                _ = loadInfoFile(realm: realm,
                                            collectionPath: collectionPath,
                                            itemPath: itemPath)
            } else if fileName.template && !templateFound {
                _ = loadTemplateFile(realm: realm,
                                                    collectionPath: collectionPath,
                                                    itemPath: itemPath)
            }
            if infoFound && templateFound {
                break
            }
        }
    }
    
    /// Attempt to load the info file.
    func loadInfoFile(realm: Realm, collectionPath: String, itemPath: String) -> Note? {
        let infoCollection = NoteCollection(realm: realm)
        infoCollection.path = collectionPath
        let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                               path2: itemPath)
        let itemURL = URL(fileURLWithPath: itemFullPath)
        let infoNt = readNote(collection: infoCollection, noteURL: itemURL)
        guard let infoNote = infoNt else { return nil }

        collection!.title = infoNote.title.value
        
        let otherFieldsField = infoNote.getField(label: LabelConstants.otherFields)
        if otherFieldsField != nil {
            let otherFields = BooleanValue(otherFieldsField!.value.value)
            collection!.otherFields = otherFields.isTrue
        }
        
        let sortParmStr = infoNote.getFieldAsString(label: LabelConstants.sortParmCommon)
        var nsp: NoteSortParm = sortParm
        nsp.str = sortParmStr
        sortParm = nsp
        
        let sortDescField = infoNote.getField(label: LabelConstants.sortDescending)
        if sortDescField != nil {
            let sortDescending = BooleanValue(sortDescField!.value.value)
            collection!.sortDescending = sortDescending.isTrue
        }
        
        let doubleBracketField = infoNote.getField(label: LabelConstants.doubleBracketParsingCommon)
        if doubleBracketField != nil {
            let doubleBracketParsing = BooleanValue(doubleBracketField!.value.value)
            collection!.doubleBracketParsing = doubleBracketParsing.isTrue
        }
        
        let noteFileFormatField = infoNote.getField(label: LabelConstants.noteFileFormat)
        if noteFileFormatField != nil {
            let noteFileFormat = NoteFileFormat(rawValue: noteFileFormatField!.value.value)
            if noteFileFormat != nil {
                collection!.noteFileFormat = noteFileFormat!
            } else {
                logError("\(noteFileFormatField!.value.value) is an invalid INFO file value for the key \(LabelConstants.noteFileFormat).")
            }
        }
        
        infoFound = true
        return infoNote
    }
    
    /// Attempt to load the template file.
    func loadTemplateFile(realm: Realm, collectionPath: String, itemPath: String) -> Note? {
        let dict = collection!.dict
        let types = collection!.typeCatalog
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.title)
        let itemFullPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                               path2: itemPath)
        let fileName = FileName(itemFullPath)
        let itemURL = URL(fileURLWithPath: itemFullPath)
        let templateNt = readNote(collection: collection!, noteURL: itemURL)
        
        guard let templateNote = templateNt else { return nil }
        guard templateNote.fields.count > 0 else { return nil }
        guard collection!.dict.count > 0 else { return nil }

        templateFound = true
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.body)
        for def in collection!.dict.list {
            if def.fieldLabel.commonForm == LabelConstants.timestampCommon {
                collection!.hasTimestamp = true
            }
            let val = templateNote.getFieldAsValue(label: def.fieldLabel.commonForm)
            if val.value.hasPrefix("<") && val.value.hasSuffix(">") {
                var typeStr = ""
                for char in val.value {
                    if char != "<" && char != ">" {
                        typeStr.append(char)
                    }
                }
                def.fieldType = collection!.typeCatalog.assignType(label: def.fieldLabel, type: typeStr)
            }
        }
        collection!.dict.lock()
        collection!.preferredExt = fileName.extLower
        let templateStatusValue = templateNote.status.value
        if templateStatusValue.count > 1 {
            let config = collection!.statusConfig
            config.set(templateStatusValue)
            collection!.typeCatalog.statusValueConfig = config
        }
        return templateNote
    }
    
    /// Reload the note in memory from the backing data store. 
    func reloadNote(_ noteToReload: Note) -> Note? {
        var ok = false
        guard collection != nil && collectionOpen else { return nil }
        guard let noteURL = noteToReload.fileInfo.url else { return nil }
        let reloaded = readNote(collection: collection!, noteURL: noteURL)
        guard reloaded!.hasTitle() else { return nil }
        if reloaded != nil {
            ok = bunch!.delete(note: noteToReload)
            guard ok else { return nil }
            if collection!.hasTimestamp {
                if !reloaded!.hasTimestamp() {
                    _ = reloaded!.setTimestamp("")
                }
            }
            ok = bunch!.add(note: reloaded!)
        }
        if ok {
            return reloaded
        } else {
            return nil
        }
    }
    
    /// Load attachments from the files folder.
    func loadAttachments() {
        guard let filesPath = getAttachmentsLocation() else { return }
        do {
            attachments = try fileManager.contentsOfDirectory(atPath: filesPath)
            attachments!.sort()
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .info,
                              message: "\(attachments!.count) Attachments loaded for the Collection")
        } catch {
            // If no files folder, then just move on.
        }
    }
    
    /// Add matching attachments to a Note. 
    func addAttachments(to note: Note) {
        guard let base = note.fileInfo.base else { return }
        guard attachments != nil else { return }
        var i = 0
        var looking = true
        while i < attachments!.count && looking {
            if attachments![i].hasPrefix(base) {
                let attachmentName = AttachmentName()
                attachmentName.setName(note: note, fullName: attachments![i])
                note.attachments.append(attachmentName)
                attachments!.remove(at: i)
            } else if base < attachments![i] {
                looking = false
            } else {
                i += 1
            }
        }
    }
    
    /// Add the specified attachment to the given note.
    ///
    /// - Parameters:
    ///   - from: The location of the file to be attached.
    ///   - to: The Note to which the file is to be attached.
    ///   - with: The unique identifier for this attachment for this note.
    /// - Returns: True if attachment added successfully, false if any sort of failure.
    func addAttachment(from: URL, to: Note, with: String) -> Bool {
        let attachmentName = AttachmentName()
        attachmentName.setName(fromFile: from, note: to, suffix: with)
        guard let attachmentURL = getURLforAttachment(attachmentName: attachmentName) else {
            logError("Couldn't get a URL for the attachment named '\(attachmentName.fullName)'")
            return false
        }
        let exists = fileManager.fileExists(atPath: attachmentURL.path)
        if exists {
            logError("Attachment already exists at \(attachmentURL.path)")
            return false
        }
        let folderOK = FileUtils.ensureFolder(forFile: attachmentURL.path)
        guard folderOK else { return false }
        do {
            try fileManager.copyItem(at: from, to: attachmentURL)
        } catch {
            logError("Couldn't copy the attachment to \(attachmentURL.path)")
            return false
        }
        to.attachments.append(attachmentName)
        return true
    }
    
    /// Reattach the attachments for this note to make sure they are attached
    /// to the new note.
    ///
    /// - Parameters:
    ///   - note1: The Note to which the files were previously attached.
    ///   - note2: The Note to wich the files should now be attached.
    /// - Returns: True if successful, false otherwise.
    func reattach(from: Note, to: Note) -> Bool {
        guard from.attachments.count > 0 else { return true }
        guard let fromNoteName = from.fileInfo.base else { return false }
        guard let toNoteName = to.fileInfo.base else { return false }
        if fromNoteName == toNoteName { return true }
        to.attachments = []
        var allOK = true
        for attachment in from.attachments {
            var ok = false
            let newAttachmentName = attachment.copy() as! AttachmentName
            newAttachmentName.changeNote(note: to)
            if let fromURL = getURLforAttachment(fileName: attachment.fullName) {
                if let toURL = getURLforAttachment(fileName: newAttachmentName.fullName) {
                    do {
                        try fileManager.moveItem(at: fromURL, to: toURL)
                        to.attachments.append(newAttachmentName)
                        ok = true
                    } catch {
                        logError("Trouble moving attachments along with modified Title")
                    }
                }
            }
            if !ok {
                allOK = false
            }
        }
        return allOK
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(attachmentName: AttachmentName) -> URL? {
        return getURLforAttachment(fileName: attachmentName.fullName)
    }
    
    /// If possible, return a URL to locate the indicated attachment.
    func getURLforAttachment(fileName: String) -> URL? {
        guard let folderPath = getAttachmentsLocation() else { return nil }
        let attachmentPath = FileUtils.joinPaths(path1: folderPath, path2: fileName)
        return URL(fileURLWithPath: attachmentPath)
    }
    
    /// Return a path to the storage location for attachments.
    func getAttachmentsLocation() -> String? {
        return FileUtils.joinPaths(path1: collectionFullPath!,
                                   path2: filesFolderName)
    }
    
    /// Load A list of available reports from the reports folder.
    func loadReports() {
        reports = []
        let reportsPath = FileUtils.joinPaths(path1: collectionFullPath!,
                                              path2: reportsFolderName)
        do {
            let reportsDirContents = try fileManager.contentsOfDirectory(atPath: reportsPath)
            
            var scriptsFound = false
            for itemPath in reportsDirContents {
                if itemPath.hasSuffix(scriptExt) {
                    scriptsFound = true
                }
            }
            
            for itemPath in reportsDirContents {
                let itemFullPath = FileUtils.joinPaths(path1: reportsPath,
                                                       path2: itemPath)
                let fileName = FileName(itemFullPath)
                if itemPath.hasSuffix(scriptExt) {
                    let report = MergeReport()
                    report.reportName = fileName.base
                    report.reportType = fileName.ext
                    reports.append(report)
                } else if !scriptsFound && fileName.baseLower.contains(templateID) {
                    let report = MergeReport()
                    report.reportName = fileName.base
                    report.reportType = fileName.ext
                    reports.append(report)
                }
            }
        } catch let error {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Failed reading contents of directory: \(error)")
        }
    }
    
    /// Attempt to initialize the collection at the provided path.
    ///
    /// - Parameter realm: The realm housing the collection to be opened.
    /// - Parameter collectionPath: The path identifying the collection within this realm
    /// - Returns: True if successful, false otherwise.
    func initCollection(realm: Realm, collectionPath: String) -> Bool {
        closeCollection()
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .info,
                          message: "Initializing Collection")
        self.realm = realm
        self.provider = realm.provider
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .info,
                          message: "Realm:      " + realm.path)
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .info,
                          message: "Collection: " + collectionPath)
        
        // Let's see if we have an actual path to a usable directory
        var collectionURL: URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: collectionPath)
        } else if collectionPath == "" || collectionPath == " " {
            collectionURL = URL(fileURLWithPath: realm.path)
        } else if collectionPath.starts(with: realm.path) {
            collectionURL = URL(fileURLWithPath: collectionPath)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(collectionPath)
        }
        collectionFullPath = collectionURL.path
        if !fileManager.fileExists(atPath: collectionFullPath!) {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Collection folder does not exist")
            return false
        }
        if !collectionURL.hasDirectoryPath {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
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
        let types = collection!.typeCatalog
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.title)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.tags)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.link)
        _ = dict.addDef(typeCatalog: types, label: LabelConstants.body)
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
            logError("Collection folder does not exist")
            return false
        }
        collectionFullPath = collectionURL!.path
        
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
        let added = bunch!.add(note: firstNote)
        guard added else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Couldn't add first note to internal storage")
            return false
        }
        
        firstNote.fileInfo.genFileName()
        collectionOpen = true
        ok = writeNote(firstNote)
        guard ok else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Couldn't write first note to disk!")
            collectionOpen = false
            return ok
        }
        
        collectionOpen = true
        bunch!.sortParm = collection.sortParm
        bunch!.sortDescending = collection.sortDescending
        
        return ok
    }
    
    /// Import Notes from a CSV or tab-delimited file
    ///
    /// - Parameter importer: A Row importer that will return rows and columns.
    /// - Parameter fileURL: The URL of the file to be imported.
    /// - Returns: The number of rows imported.
    func importRows(importer: RowImporter, fileURL: URL) -> Int {
        importer.setContext(consumer: self, workspace: nil)
        notesImported = 0
        guard collection != nil && collectionOpen else { return 0 }
        noteToImport = Note(collection: collection!)
        importer.read(fileURL: fileURL)
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
                    let noteCopy = note.copy() as! Note
                    noteCopy.collection = archiveIO!.collection!
                    let (archiveNote, _) = archiveIO!.addNote(newNote: noteCopy)
                    if archiveNote == nil {
                        okToDelete = false
                        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                          category: "FileIO",
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
            _ = deleteNote(note)
        }
        
        return notesToDelete.count
    }
    
    /// Save some of the collection info to make it persistent
    func persistCollectionInfo() {
        _ = saveInfoFile()
        _ = saveTemplateFile()
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
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
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
        str.append("Sort Descending: \(collection!.sortDescending)" + "\n\n")
        str.append("Other Fields Allowed: " + String(collection!.otherFields) + "\n\n")
        str.append("\(LabelConstants.doubleBracketParsing): \(collection!.doubleBracketParsing)\n\n")
        
        let filePath = collection!.makeFilePath(fileName: FileIO.infoFileName)
        
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Problem writing INFO file to disk!")
            return false
        }
        return true
    }
    
    /// Change the preferred file extension for the Collection.
    func changePreferredExt(from: String, to: String) -> Bool {
        guard collection != nil else { return false }
        var ok = true
        let fromFilePath = collection!.makeFilePath(fileName: "template." + from)
        let fromURL = StringUtils.urlFrom(str: fromFilePath)
        let toFilePath = collection!.makeFilePath(fileName: "template." + to)
        let toURL = StringUtils.urlFrom(str: toFilePath)
        guard fromURL != nil else { return false }
        guard toURL != nil else { return false }
        do {
            try fileManager.moveItem(at: fromURL!, to: toURL!)
        } catch {
            logError("Unable to rename template file from \(fromURL!) to \(toURL!) due to the following error: \(error)")
            ok = false
        }
        return ok
    }
    
    /// Save the template file into the current collection
    func saveTemplateFile() -> Bool {
        let dict = collection!.dict
        var str = ""
        for def in dict.list {
            if def.fieldLabel.commonForm == LabelConstants.timestampCommon {
                collection!.hasTimestamp = true
            }
            str.append(def.fieldLabel.properForm + ": \n\n")
        }
        let filePath = collection!.makeFilePath(fileName: "template." + collection!.preferredExt)
        do {
            try str.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Problem writing template file to disk!")
            return false
        }
        return true
    }
    
    /// Close the current collection, if one is open
    func closeCollection() {
        collection = nil
        collectionOpen = false
        if bunch != nil {
            bunch!.close()
        }
        templateFound = false
        infoFound = false
        reports = []
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
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        guard newNote.hasTitle() else { return (nil, NotePosition(index: -1)) }
        if collection!.hasTimestamp {
            if !newNote.hasTimestamp() {
                _ = newNote.setTimestamp("")
            }
        }
        let added = bunch!.add(note: newNote)
        guard added else { return (nil, NotePosition(index: -1)) }
        newNote.fileInfo.genFileName()
        let written = writeNote(newNote)
        if !written {
            return (nil, NotePosition(index: -1))
        } else {
            let (_, position) = bunch!.selectNote(newNote)
            return (newNote, position)
        }
    }
    
    /// Delete the given note
    ///
    /// - Parameter noteToDelete: The note to be deleted.
    /// - Returns: True if delete was successful, false otherwise.
    func deleteNote(_ noteToDelete: Note) -> Bool {
        print("FileIO.deleteNote titled \(noteToDelete.title.value)")
        var deleted = false
        
        guard collection != nil && collectionOpen else { return false }
        
        deleted = bunch!.delete(note: noteToDelete)
        
        guard deleted else { return false }

        // _ = noteToDelete.fullPath
        let noteURL = noteToDelete.fileInfo.url
        if noteURL != nil {
            do {
                try fileManager.removeItem(at: noteURL!)
                // try fileManager.trashItem(at: noteURL!, resultingItemURL: nil)
                // As of Oct 15, 2019, running on Catalina, trashing an item fails due
                // to alleged permission errors, while removing an item works without complaint.
            } catch {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "FileIO",
                                  level: .error,
                                  message: "Could not delete note file at '\(noteURL!.path)'")
                deleted = false
            }
        }
        
        return deleted
    }
    
    /// Write a note to disk within its collection.
    ///
    /// - Parameter note: The Note to be saved to disk.
    /// - Returns: True if saved successfully, false otherwise.
    func writeNote(_ note: Note) -> Bool {
        
        // Make sure we have an open collection available to us
        guard collection != nil && collectionOpen else { return false }
        guard !note.fileInfo.isEmpty else { return false }
        
        pickLists.registerNote(note: note)
        let writer = BigStringWriter()
        let maker = NoteLineMaker(writer)
        let fieldsWritten = maker.putNote(note)
        guard fieldsWritten > 0 else { return false }
        let stringToSave = NSString(string: writer.bigString)
        do {
            try stringToSave.write(toFile: note.fileInfo.fullPath!, atomically: true, encoding: String.Encoding.utf8.rawValue)
            let noteURL = note.fileInfo.url
            if noteURL != nil {
                updateEnvDates(note: note, noteURL: noteURL!)
            }
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Problem writing Note to disk at \(note.fileInfo.fullPath!)")
            return false
        }
        return true
    }
    
    /// Read a note from disk.
    ///
    /// - Parameter noteURL: The complete URL pointing to the note file to be read.
    /// - Returns: A note composed from the contents of the indicated file,
    ///            or nil, if problems reading file.
    func readNote(collection: NoteCollection, noteURL: URL) -> Note? {
        
        let reader = BigStringReader(fileURL: noteURL)
        guard reader != nil else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Error reading Note from \(noteURL)")
            return nil
        }
        let parser = NoteLineParser(collection: collection, reader: reader!)
        let fileName = noteURL.lastPathComponent
        var defaultTitle = ""
        if fileName.count > 0 {
            let fileNameUtil = FileName(noteURL)
            defaultTitle = fileNameUtil.base
        }
        let note = parser.getNote(defaultTitle: defaultTitle)
        if fileName.count > 0 {
            note.fileInfo.baseDotExt = fileName
        }
        updateEnvDates(note: note, noteURL: noteURL)
        return note
    }
    
    /// Update the Note with the latest creation and modification dates from our storage environment
    func updateEnvDates(note: Note, noteURL: URL) {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: noteURL.path)
            let creationDate = attributes[FileAttributeKey.creationDate]
            let lastModDate = attributes[FileAttributeKey.modificationDate]
            if creationDate != nil {
                let creationDateStr = String(describing: creationDate!)
                note.envCreateDate = creationDateStr
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "FileIO",
                                  level: .error,
                                  message: "Inscrutable creation date for note at \(noteURL.path)")
            }
            if (lastModDate != nil) {
                let lastModDateStr = String(describing: lastModDate!)
                note.envModDate = lastModDateStr
            } else {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "FileIO",
                                  level: .error,
                                  message: "Inscrutable modification date for note at \(noteURL.path)")
            }
        }
        catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileIO",
                              level: .error,
                              message: "Unable to obtain file attributes for for note at \(noteURL.path)")
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
    
    /// Return the number of notes in the current collection.
    ///
    /// - Returns: The number of notes in the current collection
    var notesCount: Int {
        guard bunch != nil else { return 0 }
        return bunch!.count
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
    
    /// Return the note currently selected.
    ///
    /// If the list index is out of range, return a nil Note and an index posiiton of -1.
    func getSelectedNote() -> (Note?, NotePosition) {
        guard collection != nil && collectionOpen else { return (nil, NotePosition(index: -1)) }
        return bunch!.getSelectedNote()
    }
    
    /// Delete the currently selected Note, plus any attachments it might have. 
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
 
        _ = bunch!.delete(note: noteToDelete!)
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
        
        let notePath = noteToDelete!.fileInfo.fullPath
        let noteURL = noteToDelete!.fileInfo.url
        if noteURL != nil {
            for attachment in noteToDelete!.attachments {
                let attachmentURL = getURLforAttachment(attachmentName: attachment)
                if attachmentURL != nil {
                    do {
                        try fileManager.removeItem(at: attachmentURL!)
                        // try fileManager.trashItem(at: attachmentURL!, resultingItemURL: nil)
                        // As of Oct 15, 2019, running on Catalina, trashing an item fails due
                        // to alleged permission errors, while removing an item works without complaint.
                    } catch {
                        logError("Unable to delete attachment at \(attachmentURL!.path)")
                    }
                }
            }
            do {
                // try fileManager.removeItem(at: noteURL!)
                // try fileManager.trashItem(at: noteURL!, resultingItemURL: nil)
                try fileManager.removeItem(atPath: notePath!)
                // As of Oct 15, 2019, running on Catalina, trashing an item fails due
                // to alleged permission errors, while removing an item works without complaint.
            } catch {
                logError("Could not delete selected note file at '\(noteURL!.path)'")
            }
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
    
    /// Send an informative message to the log.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .info,
                          message: msg)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "FileIO",
                          level: .error,
                          message: msg)
    }
}
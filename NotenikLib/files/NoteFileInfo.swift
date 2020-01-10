//
//  NoteFileName.swift
//  Notenik
//
//  Created by Herb Bowie on 1/6/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The file name for a Note stored on disk.
class NoteFileInfo {
    
    var note: Note
    var collection: NoteCollection
    
    var format: NoteFileFormat = .toBeDetermined
    var mmdMetaStartLine = ""
    var mmdMetaEndLine = ""
    
    /// This should contain the file name (without the path) plus the file extension
    var base: String?
    var ext:  String?
    var matchesIDSource = true
    
    init(note: Note) {
        self.note = note
        self.collection = note.collection
        format = collection.noteFileFormat 
    }
    
    /// Does this note have a file name?
    var isEmpty: Bool {
        return base == nil
            || ext == nil
            || base!.count == 0
            || ext!.count == 0
    }
    
    /// Return the full file path for the Note
    var fullPath: String? {
        if self.isEmpty {
            return nil
        } else {
            return FileUtils.joinPaths(path1: note.collection.collectionFullPath, path2: baseDotExt!)
        }
    }
    
    /// Return the full URL pointing to the Note's file
    var url: URL? {
        let path = fullPath
        guard path != nil else { return nil }
        return URL(fileURLWithPath: path!)
    }
    
    /// If the file name matched the ID source before, then regen it; if the filename did
    /// not match the ID source before, then leave it alone. 
    func optRegenFileName() {
        if matchesIDSource {
            genFileName()
        }
    }
    
    /// Create a file name for the file, based on the Note's title
    func genFileName() {
        guard collection.preferredExt.count > 0 else { return }
        let source = note.noteIDSource
        guard source.count > 0 else { return }
        if note.hasTitle() {
            base = StringUtils.toReadableFilename(note.title.value)
            ext = collection.preferredExt
            matchesIDSource = true
        }
    }
    
    /// Set the flag indicating whether the file name matches the Note's ID.
    func checkIDSourceMatch() {
        guard base != nil else { return }
        matchesIDSource = (StringUtils.toCommon(base!) == StringUtils.toCommon(note.noteIDSource))
    }
    
    /// The filename consisting of a base, plus a dot, plus the extension.
    var baseDotExt: String? {
        
        // Concatenate base, dot and extension.
        get {
            if self.isEmpty {
                return nil
            } else {
                return base! + "." + ext!
            }
        }
        
        // Separate out base from extension. 
        set {
            guard newValue != nil  else {
                base = nil
                ext = nil
                return
            }
            base = ""
            ext = ""
            var dotFound = false
            for char in newValue! {
                if char == "." {
                    dotFound = true
                    if ext!.count > 0 {
                        base!.append(".")
                        base!.append(ext!)
                        ext = ""
                    }
                } else if dotFound {
                    ext!.append(char)
                } else {
                    base!.append(char)
                }
            }
            checkIDSourceMatch()
        }
    }
    
}

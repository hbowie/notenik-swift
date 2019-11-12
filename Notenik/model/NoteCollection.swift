//
//  NoteCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Information about a collection of Notes.
class NoteCollection {
    
    var path  = ""
    var title = ""
    var realm        : Realm
    var noteType     : NoteType = .general
    var dict         : FieldDictionary
    var idRule       : NoteIDRule
    var sortParm     : NoteSortParm
    var sortDescending: Bool
    var typeCatalog =  AllTypes()
    var statusConfig : StatusValueConfig
    /// Preferred file extension for the current collection
    var preferredExt : String = "txt"
    var otherFields  = false
    var readOnly     : Bool = false
    var customFields : [SortField] = []
    
    ///Is this collection a collection of collections within a parent realm?
    var isRealmCollection = false
    
    /// Default initialization of a new Realm.
    init () {
        realm = Realm()
        dict = FieldDictionary()
        idRule = NoteIDRule.fromTitle
        sortParm = .title
        sortDescending = false
        statusConfig = StatusValueConfig()
    }
    
    /// Convenience initialization that identifies the Realm. 
    convenience init (realm : Realm) {
        self.init()
        self.realm = realm
    }
    
    var collectionFullPathURL: URL? {
        var collectionURL: URL
        if realm.path == "" || realm.path == " " {
            collectionURL = URL(fileURLWithPath: path)
        } else {
            let realmURL = URL(fileURLWithPath: realm.path)
            collectionURL = realmURL.appendingPathComponent(path)
        }
        return collectionURL
    }
    
    /// The complete path to this collection, represented as a String
    var collectionFullPath: String {
        if realm.path == "" || realm.path == " " {
            return path
        } else {
            return FileUtils.joinPaths(path1: realm.path, path2: path)
        }
    }
    
    /// Make a complete path to a file residing within this collection
    func makeFilePath(fileName: String) -> String {
        return FileUtils.joinPaths(path1: collectionFullPath, path2: fileName)
    }
    
    /// Attempt to obtain or create a Field Definition for the given Label.
    ///
    /// Note that the Collection's Field Dictionary may be updated as part of this call.
    ///
    /// - Parameter label: A field label. The validLabel field will be updated as part of this call.
    /// - Returns: A Field Definition for this Label, if the label is valid, otherwise nil.
    func getDef(label: inout FieldLabel) -> FieldDefinition? {
        label.validLabel = false
        var def: FieldDefinition? = nil
        if label.commonForm.count > 48 {
            // Too long
        } else if (label.commonForm == "http"
            || label.commonForm == "https"
            || label.commonForm == "ftp"
            || label.commonForm == "mailto") {
            // Let's not confuse a URL with a field label
        } else if dict.contains(label) {
            label.validLabel = true
            def = dict.getDef(label)
        } else if dict.locked && label.commonForm == LabelConstants.dateAddedCommon {
            label.validLabel = true
            dict.unlock()
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
            dict.lock()
        } else if dict.locked {
            // Can't add any additional labels
        } else if label.isTitle || label.isTags || label.isLink || label.isBody || label.isDateAdded {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        } else if noteType == .simple {
            // No other labels allowed for simple notes
        } else if label.isAuthor
                || label.isCode
                || label.isDate
                || label.isIndex
                || label.isRating
                || label.isRecurs
                || label.isSeq
                || label.isStatus
                || label.isTeaser
                || label.isType
                || label.isWorkTitle {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        } else if noteType == .expanded {
            // No other labels allowed for expanded notes
        } else {
            label.validLabel = true
            def = dict.addDef(typeCatalog: typeCatalog, label: label)
        }
        return def
    }
}

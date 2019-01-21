//
//  NoteCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Representing a collection of Notes.
class NoteCollection {
    
    var path  = ""
    var title = ""
    var realm        : Realm
    var noteType     : NoteType = .general
    var dict         : FieldDictionary
    var idRule       : NoteIDRule
    var sortParm     : NoteSortParm
    var statusConfig : StatusValueConfig
    
    /// Default initialization of a new Realm.
    init () {
        realm = Realm()
        dict = FieldDictionary()
        idRule = NoteIDRule.fromTitle
        sortParm = .title
        statusConfig = StatusValueConfig()
    }
    
    /// Convenience initialization that identifies the Realm. 
    convenience init (realm : Realm) {
        self.init()
        self.realm = realm
    }
    
    /// Attempt to obtain or create a Field Definition for the given Label.
    ///
    /// Note that the Collection's Field Dictionary may be updated as part of this call.
    ///
    /// - Parameter label: A field label. The validLabel field will be updated as part of this call.
    /// - Returns: A Field Definition for this Label, if the label is valid, otherwise nil.
    func getDef(label: inout FieldLabel) -> FieldDefinition? {
        label.validLabel = false
        var def : FieldDefinition? = nil
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
            def = dict.addDef(label)
            dict.lock()
        } else if dict.locked {
            // Can't add any additional labels
        } else if label.isTitle || label.isTags || label.isLink || label.isBody || label.isDateAdded {
            label.validLabel = true
            def = dict.addDef(label)
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
            def = dict.addDef(label)
        } else if noteType == .expanded {
            // No other labels allowed for expanded notes
        } else {
            label.validLabel = true
            def = dict.addDef(label)
        }
        return def
    }
}

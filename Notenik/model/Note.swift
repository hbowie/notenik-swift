//
//  Note.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

class Note: Comparable {
    
    static func < (lhs: Note, rhs: Note) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.sortKey == rhs.sortKey
    }
    
    var collection : NoteCollection
    
    var fields = [:] as [String: NoteField]
    
    /// Return the Note's Author Value
    var author: AuthorValue {
        let val = getFieldAsValue(label: LabelConstants.author)
        if val is AuthorValue {
            return val as! AuthorValue
        } else {
            return AuthorValue(val.value)
        }
    }
    
    /// Return the Note's Date Value
    var date: DateValue {
        let val = getFieldAsValue(label: LabelConstants.date)
        if val is DateValue {
            return val as! DateValue
        } else {
            return DateValue(val.value)
        }
    }
    
    /// Return the Note's Link Value
    var link: LinkValue {
        let val = getFieldAsValue(label: LabelConstants.link)
        if val is LinkValue {
            return val as! LinkValue
        } else {
            return LinkValue(val.value)
        }
    }
    
    /// Return the Note's Link Value (if any) as a possible URL
    var linkAsURL: URL? {
        let val = getFieldAsValue(label: LabelConstants.link)
        if val is LinkValue {
            let linkVal = val as! LinkValue
            return linkVal.url
        } else {
            return nil
        }
    }
    
    /// Return the Note's Sequence Value
    var seq: SeqValue {
        let val = getFieldAsValue(label: LabelConstants.seq)
        if val is SeqValue {
            return val as! SeqValue
        } else {
            return SeqValue(val.value)
        }
    }
    
    /// Return the Note's Status Value
    var status: StatusValue {
        let val = getFieldAsValue(label: LabelConstants.status)
        if val is StatusValue {
            return val as! StatusValue
        } else {
            return StatusValue(val.value)
        }
    }
    
    /// Return the Note's Title Value
    var title: TitleValue {
        let val = getFieldAsValue(label: LabelConstants.title)
        if val is TitleValue {
            return val as! TitleValue
        } else {
            return TitleValue(val.value)
        }
    }
    
    /// Return the Note's Tags Value
    var tags: TagsValue {
        let val = getFieldAsValue(label: LabelConstants.tags)
        if val is TagsValue {
            return val as! TagsValue
        } else {
            return TagsValue(val.value)
        }
    }
    
    /// Return the Body of the Note
    var body: LongTextValue {
        let val = getFieldAsValue(label: LabelConstants.body)
        if val is LongTextValue {
            return val as! LongTextValue
        } else {
            return LongTextValue(val.value)
        }
    }
    
    
    /// Initialize without any input
    init() {
        collection = NoteCollection()
    }
    
    /// Initialize with a Collection
    convenience init (collection : NoteCollection) {
        self.init()
        self.collection = collection
    }
    
    /// Get the unique ID used to identify this note within its collection
    var noteID : String {
        switch collection.idRule {
        case .fromTitle:
            return StringUtils.toCommon(title.value)
        default:
            return StringUtils.toCommon(title.value)
        }
    }
    
    var sortKey : String {
        switch collection.sortParm {
        case .title:
            return title.sortKey
        case .seqPlusTitle:
            return seq.sortKey + title.sortKey
        case .tasksByDate:
            return (status.doneX(config: collection.statusConfig)
                + date.sortKey
                + seq.sortKey
                + title.sortKey)
        case .tasksBySeq:
            return (status.doneX(config: collection.statusConfig)
                + seq.sortKey
                + date.sortKey
                + title.sortKey)
        case .author:
            return (author.sortKey
                + date.sortKey
                + title.sortKey)
        }
    }
    
    /// Does this note have a non-blank title field?
    func hasTitle() -> Bool {
        return title.count > 0
    }
    
    /// Does this note have a non-blank tags field?
    func hasTags() -> Bool {
        return tags.count > 0
    }
    
    /// Does this note have a non-blank body?
    func hasBody() -> Bool {
        return body.count > 0
    }
    
    /// Does this Note contain a title?
    func containsTitle() -> Bool {
        return contains(label: LabelConstants.title)
    }
    
    /// Get the Title field, if one exists
    func getTitleAsField() -> NoteField? {
        return getField(label: LabelConstants.title)
    }
    
    /// Get the body field, if one exists
    func getBodyAsField() -> NoteField? {
        return getField(label: LabelConstants.body)
    }
    
    /// See if the note contains a field with the given label.
    ///
    /// - Parameter label: A string label expressed in either its proper or common form.
    /// - Returns: True if the note has such a field and the value is non-blank, false otherwise.
    func contains(label : String) -> Bool {
        let fieldLabel = FieldLabel(label)
        let field = fields[fieldLabel.commonForm]
        return field != nil && field!.value.hasData
    }
    
    /// Get the field for the passed label, and return the field value as a string
    func getFieldAsString(label: String) -> String {
        let field = getField(label: label)
        if field == nil {
            return ""
        } else {
            return field!.value.value
        }
    }
    
    /// Return the value for the Note field identified by the passed label.
    ///
    /// - Parameter label: The label identifying the desired field.
    /// - Returns: A StringValue or one of its descendants
    func getFieldAsValue(label: String) -> StringValue {
        let field = getField(label: label)
        if field == nil {
            return StringValue("")
        } else {
            return field!.value
        }
    }
    
    /// Get the Note Field for a particular label
    func getField (label: String) -> NoteField? {
        let fieldLabel = FieldLabel(label)
        return fields[fieldLabel.commonForm]
    }
    
    /// Get the Note Field for a particular Field Definition
    ///
    /// - Parameter def: A Field Definition (typically from a Field Dictionary)
    /// - Returns: The corresponding field within this Note, if one exists for this definition
    func getField(def: FieldDefinition) -> NoteField? {
        return fields[def.fieldLabel.commonForm]
    }
    
    /// Add a field to the note.
    ///
    /// - Parameter field: A complete Note Field, including definition and value.
    /// - Returns: True if added successfully, false otherwise.
    func addField(_ field : NoteField) -> Bool {
        if collection.dict.contains(field.def) {
            if fields[field.def.fieldLabel.commonForm] != nil {
                /// field is already part of the note -- can't add it
                return false
            } else {
                /// Add field that's already present in the dictionary
                fields[field.def.fieldLabel.commonForm] = field
                return true
            }
        } else if collection.dict.locked {
            /// If field not already in dictionary, and dictionary is locked, then we can't add it
            return false
        } else {
            /// Add the field to the dictionary and the note
            let def = collection.dict.addDef(field.def)!
            fields[def.fieldLabel.commonForm] = field
            return true
        }
    }
    
    /// Set the indicated field to the passed Note Field
    ///
    /// - Parameter field: The Note field we want to set.
    /// - Returns: True if the field was set, false otherwise.
    func setField(_ field : NoteField) -> Bool {
        if (field.def.fieldType == .status
            && field.value.value.count > 0
            && field.value is StatusValue) {
            let statusVal = field.value as! StatusValue
            if statusVal.getInt() == 0 {
                statusVal.set(str: field.value.value, config: collection.statusConfig)
            }
        }
        if collection.dict.contains(field.def) {
            fields[field.def.fieldLabel.commonForm] = field
            return true
        } else if collection.dict.locked {
            /// If field not already in dictionary, and dictionary is locked, then we can't add it
            return false
        } else {
            /// Add the field to the dictionary and the note
            let def = collection.dict.addDef(field.def)!
            fields[def.fieldLabel.commonForm] = field
            return true
        }
    }
    
    func display() {
        print(" ")
        print ("Note.display")
        for def in collection.dict.list {
            print ("Field Label Proper: \(def.fieldLabel.properForm) + common: \(def.fieldLabel.commonForm) + type: \(def.fieldType)")
            let field = fields[def.fieldLabel.commonForm]
            if field == nil {
                print(" - No value found for this field for this Note")
            } else {
                let val = field!.value
                print("  - Type  = " + String(describing: type(of: val)))
                print("  - Value = " + val.value)
            }
        }
    }
}

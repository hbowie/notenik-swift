//
//  Note.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single Note. 
class Note: Comparable, NSCopying {
    
    var collection:  NoteCollection
    
    var fields = [:] as [String: NoteField]
    var attachments: [AttachmentName] = []
    
    var _envCreateDate = ""
    var _envModDate    = ""
    
    /// This should contain the file name (without the path) plus the file extension
    var fileNameBase: String?
    var fileNameExt:  String?
    
    var fileName: String? {
        get {
            if fileNameBase == nil || fileNameExt == nil {
                return nil
            } else {
                return fileNameBase! + "." + fileNameExt!
            }
        }
        set {
            if newValue == nil {
                fileNameBase = nil
                fileNameExt = nil
            } else {
                fileNameBase = ""
                fileNameExt = ""
                var dotFound = false
                for char in newValue! {
                    if char == "." {
                        dotFound = true
                        if fileNameExt!.count > 0 {
                            fileNameBase!.append(".")
                            fileNameBase!.append(fileNameExt!)
                            fileNameExt = ""
                        }
                    } else if dotFound {
                        fileNameExt!.append(char)
                    } else {
                        fileNameBase!.append(char)
                    }
                }
            }
        }
    }
    
    /// Initialize with a Collection
    init (collection: NoteCollection) {
        // self.init()
        self.collection = collection
    }
    
    var envCreateDate: String {
        get {
            return _envCreateDate
        }
        set {
            _envCreateDate = newValue
            let dateAddedDef = collection.dict.getDef(LabelConstants.dateAdded)
            if dateAddedDef != nil {
                let dateAddedValue = dateAdded
                if dateAddedValue.value.count == 0 {
                    _ = setDateAdded(newValue)
                }
            }
        }
    }
    
    var envModDate: String {
        get {
            return _envModDate
        }
        set {
            _envModDate = newValue
        }
    }
    
    /// Return the full URL pointing to the Note's file
    var url: URL? {
        let path = fullPath
        if path == nil {
            return nil
        } else {
            return URL(fileURLWithPath: path!)
        }
    }
    
    /// Return the full file path for the Note
    var fullPath: String? {
        if hasFileName() {
            return FileUtils.joinPaths(path1: collection.collectionFullPath, path2: fileName!)
        } else {
            return nil
        }
    }
    
    /// Create a file name for the file, based on the Note's title
    func makeFileNameFromTitle() {
        guard collection.preferredExt.count > 0 else { return }
        if hasTitle() {
            fileName = StringUtils.toReadableFilename(title.value) + "." + collection.preferredExt
        }
    }
    
    static func < (lhs: Note, rhs: Note) -> Bool {
        if lhs.collection.sortParm == .custom {
            return compareCustomFields(lhs: lhs, rhs: rhs) < 0
        } else {
            return lhs.sortKey < rhs.sortKey
        }
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        if lhs.collection.sortParm == .custom {
            return compareCustomFields(lhs: lhs, rhs: rhs) == 0
        } else {
            return lhs.sortKey == rhs.sortKey
        }
    }
    
    static func compareCustomFields(lhs: Note, rhs: Note) -> Int {
        var result = 0
        var index = 0
        while index < lhs.collection.customFields.count && result == 0 {
            let sortField = lhs.collection.customFields[index]
            let def = sortField.field
            let field1 = lhs.getField(def: def)
            var value1 = StringValue()
            if field1 != nil {
                value1 = field1!.value
            }
            let field2 = rhs.getField(def: def)
            var value2 = StringValue()
            if field2 != nil {
                value2 = field2!.value
            }
            if value1 < value2 {
                result = sortField.ascending ? -1 :  1
            } else if value1 > value2 {
                result = sortField.ascending ?  1 : -1
            } else {
                index += 1
            }
        }

        return result
    }
    
    /// Make a copy of this Note
    func copy(with zone: NSZone? = nil) -> Any {
        let newNote = Note(collection: collection)
        if fileName == nil {
            newNote.fileName = nil
        } else {
            newNote.fileName = String(fileName!)
        }
        copyFields(to: newNote)
        copyAttachments(to: newNote)
        return newNote
    }
    
    /// Copy field values from this Note to a second Note, making sure all fields have
    /// matching definitions and values.
    ///
    /// - Parameter note2: The Note to be updated with this Note's field values.
    func copyFields(to note2: Note) {

        let dict = collection.dict
        let defs = dict.list
        for definition in defs {
            let field = getField(def: definition)
            let field2 = note2.getField(def: definition)
            if field == nil && field2 == nil {
                // Nothing to do here -- just move on
            } else if field == nil && field2 != nil {
                field2!.value.set("")
            } else if field != nil && field2 == nil {
                _ = note2.addField(def: definition, strValue: field!.value.value)
            } else {
                field2!.value.set(field!.value.value)
            }
        }
    }
    
    /// Copy attachment file names from this note to another one. 
    func copyAttachments(to note2: Note) {
        for attachment in attachments {
            let attachment2 = attachment
            note2.attachments.append(attachment2)
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    func close() {
        if hasDate() && hasRecurs() {
            recur()
        } else if hasStatus()  {
            status.close(config: collection.statusConfig)
        }
    }
    
    /// Bump the Note's Date up by 1
    func incrementDate() {
        
    }
    
    /// Apply the recurs rule to the note
    func recur() {
        if hasDate() && hasRecurs() {
            let dateVal = date
            let recursVal = recurs
            let newDate = recursVal.recur(dateVal)
            dateVal.set(String(describing: newDate))
        }
    }
    
    /// Set the Note's Title value
    func setTitle(_ title: String) -> Bool {
        return setField(label: LabelConstants.title, value: title)
    }
    
    /// Set the Note's Link value
    func setLink(_ link: String) -> Bool {
        return setField(label: LabelConstants.link, value: link)
    }
    
    /// Set the Note's Tags value
    func setTags(_ tags: String) -> Bool {
        return setField(label: LabelConstants.tags, value: tags)
    }
    
    /// Set the Note's Status value
    func setStatus(_ status: String) -> Bool {
        return setField(label: LabelConstants.status, value: status)
    }
    
    /// Set the Note's Date value
    func setDate(_ date: String) -> Bool {
        return setField(label: LabelConstants.date, value: date)
    }
    
    /// Set the Note's Sequence value
    func setSeq(_ seq: String) -> Bool {
        return setField(label: LabelConstants.seq, value: seq)
    }
    
    /// Set the Note's Index value
    func setIndex(_ index: String) -> Bool {
        return setField(label: LabelConstants.index, value: index)
    }
    
    /// Append additional data to the Index Value
    func appendToIndex(_ index: String) {
        let field = getField(label: LabelConstants.index)
        if field == nil {
            _ = setIndex(index)
        } else {
            let val = field!.value
            if val is IndexValue {
                let indexVal = val as! IndexValue
                indexVal.append(index)
            }
        }
    }
    
    /// Set the Note's Code value
    func setCode(_ code: String) -> Bool {
        return setField(label: LabelConstants.code, value: code)
    }
    
    /// Set the Note's Body value
    func setBody(_ body: String) -> Bool {
        return setField(label: LabelConstants.body, value: body)
    }
    
    /// Set the Note's Date Added field
    func setDateAdded(_ dateAdded: String) -> Bool {
        return setField(label: LabelConstants.dateAdded, value: dateAdded)
    }
    
    /// Return the Note's Author Value
    var author: AuthorValue {
        let val = getFieldAsValue(label: LabelConstants.author)
        if val is AuthorValue {
            return val as! AuthorValue
        } else {
            return AuthorValue(val.value)
        }
    }
    
    /// Return the Note's Code Value
    var code: LongTextValue {
        let val = getFieldAsValue(label: LabelConstants.code)
        if val is LongTextValue {
            return val as! LongTextValue
        } else {
            return LongTextValue(val.value)
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
    
    /// Does this note recur on a daily basis?
    var daily: Bool {
        guard let recursVal = getFieldAsValue(label: LabelConstants.recurs) as? RecursValue else { return false }
        return recursVal.daily
    }
    
    /// Return the Note's Recurs Value
    var recurs: RecursValue {
        let val = getFieldAsValue(label: LabelConstants.recurs)
        if val is RecursValue {
            return val as! RecursValue
        } else {
            return RecursValue(val.value)
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
    
    /// Return the Note's Index Value
    var index: IndexValue {
        let val = getFieldAsValue(label: LabelConstants.index)
        if val is IndexValue {
            return val as! IndexValue
        } else {
            return IndexValue(val.value)
        }
    }
    
    /// Is the user done with this item? 
    var isDone: Bool {
        let val = getFieldAsValue(label: LabelConstants.status)
        guard let status = val as? StatusValue else { return false }
        return status.isDone(config: collection.statusConfig)
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
    
    /// Return the date the note was originally added
    var dateAdded: DateValue {
        let val = getFieldAsValue(label: LabelConstants.dateAdded)
        if val is DateValue {
            return val as! DateValue
        } else {
            return DateValue(val.value)
        }
    }
    
    /// Get the unique ID used to identify this note within its collection
    var noteID: String {
        switch collection.idRule {
        case .fromTitle:
            return StringUtils.toCommon(title.value)
        default:
            return StringUtils.toCommon(title.value)
        }
    }
    
    /// Return a String containing the current sort key for the Note
    var sortKey: String {
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
        case .custom:
            var key = ""
            for sortField in collection.customFields {
                let def = sortField.field
                let field = getField(def: def)
                if field != nil {
                    let value = field!.value
                    key.append(value.sortKey)
                }
            }
            return key
        }
    }
    
    /// Does this note have a file name?
    func hasFileName() -> Bool {
        return fileName != nil && fileName!.count > 0
    }
    
    /// Does this note have a non-blank title field?
    func hasTitle() -> Bool {
        return title.count > 0
    }
    
    /// Does this note have a non-blank tags field?
    func hasTags() -> Bool {
        return tags.count > 0
    }
    
    // Does this note have a non-blank Sequence field?
    func hasSeq() -> Bool {
        return seq.count > 0
    }
    
    /// Does this note have a non-blank Index field?
    func hasIndex() -> Bool {
        return index.count > 0
    }
    
    /// Does this note have a non-blank date field?
    func hasDate() -> Bool {
        return date.count > 0
    }
    
    /// Does this note have a non-blank recurs field?
    func hasRecurs() -> Bool {
        return recurs.count > 0
    }
    
    /// Does this note have a non-blank status field?
    func hasStatus() -> Bool {
        return status.count > 0
    }
    
    /// Does this note have a non-blank body?
    func hasBody() -> Bool {
        return body.count > 0
    }
    
    /// Does this note have a date added?
    func hasDateAdded() -> Bool {
        return dateAdded.count > 0
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
    
    
    /// Add a field to the note, given a definition and a String value.
    ///
    /// - Parameters:
    ///   - def: A Field Definition for this field.
    ///   - strValue: A String containing the intended value for this field.
    /// - Returns: True if added successfully, false otherwise.
    func addField(def: FieldDefinition, strValue: String) -> Bool {
        let field = NoteField(def: def, value: strValue, statusConfig: collection.statusConfig)
        return addField(field)
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
    
    /// Set a Note field given a label and a value
    func setField(label: String, value: String) -> Bool {
        let field = NoteField(label: label, value: value, statusConfig: collection.statusConfig)
        return setField(field)
        
    }
    
    /// Set the indicated field to the passed Note Field
    ///
    /// - Parameter field: The Note field we want to set.
    /// - Returns: True if the field was set, false otherwise.
    func setField(_ field: NoteField) -> Bool {
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

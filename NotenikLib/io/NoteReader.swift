//
//  NoteReader.swift
//  Notenik
//
//  Created by Herb Bowie on 8/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A Note Reader that conformes to RowImporter. 
class NoteReader: RowImporter {
    
    var consumer:           RowConsumer?
    var workspace:          ScriptWorkspace?
    
    var collection:         NoteCollection?
    
    var split               = false
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    init() {
        
    }
    
    /// Initialize the class with a Row Consumer
    public func setContext(consumer: RowConsumer, workspace: ScriptWorkspace? = nil) {
        self.consumer = consumer
        self.workspace = workspace
    }
    
    /// Initialize the class with a Row Consumer
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }

    /// Read the Collection and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the Notenik Collection to be read.
    /// - Returns: The number of rows returned.
    public func read(fileURL: URL) {
        
        let io: NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        var collectionURL: URL
        if FileUtils.isDir(fileURL.path) {
            collectionURL = fileURL
        } else {
            collectionURL = fileURL.deletingLastPathComponent()
        }
        collection = io.openCollection(realm: realm, collectionPath: collectionURL.path)
        if collection == nil {
            logError("Problems opening the collection at " + collectionURL.path)
            return
        }
        
        // Build the list of labels
        if split {
            labels.append(LabelConstants.tag)
        }
        for def in collection!.dict.dict {
            labels.append(def.value.fieldLabel.properForm)
        }
        
        // Now read the notes and return fields and rows.
        var (note, position) = io.firstNote()
        while note != nil {
            var tagsWritten = 0
            if split {
                for tag in note!.tags.tags {
                    let splitTag = String(describing: tag)
                    returnNoteFields(note: note!, splitTag: splitTag)
                    tagsWritten += 1
                }
            }
            if tagsWritten == 0 {
                returnNoteFields(note: note!, splitTag: nil)
            }

            (note, position) = io.nextNote(position)
        }
        io.closeCollection()
    }
    
    func returnNoteFields(note: Note, splitTag: String?) {
        startRow()
        for label in labels {
            if split && label == LabelConstants.tag {
                if splitTag == nil {
                    anotherField(label: label, value: "")
                } else {
                    anotherField(label: label, value: splitTag!)
                }
            } else {
                let value = note.getFieldAsString(label: label)
                anotherField(label: label, value: value)
            }
        }
        anotherRow()
    }
    
    func startRow() {
        fields = []
    }
    
    func anotherField(label: String, value: String) {
        consumer!.consumeField(label: label, value: value)
        fields.append(value)
    }
    
    func anotherRow() {
        consumer!.consumeRow(labels: labels, fields: fields)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "NoteReader",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
    
}

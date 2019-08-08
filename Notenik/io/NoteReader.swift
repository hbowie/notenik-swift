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

class NoteReader: RowImporter {
    
    var consumer:           RowConsumer?
    var workspace:          ScriptWorkspace?
    
    var collection:         NoteCollection?
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    var rowsReturned        = 0
    
    init() {
        
    }
    
    /// Initialize the class with a Row Consumer
    func setContext(consumer: RowConsumer, workspace: ScriptWorkspace? = nil) {
        self.consumer = consumer
        self.workspace = workspace
    }

    /// Read the Collection and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the Notenik Collection to be read.
    /// - Returns: The number of rows returned.
    func read(fileURL: URL) -> Int {
        
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
            return 0
        }
        
        for def in collection!.dict.dict {
            labels.append(def.value.fieldLabel.properForm)
        }
        
        rowsReturned = 0
        var (note, position) = io.firstNote()
        while note != nil {
            fields = []
            for label in labels {
                let value = note!.getFieldAsString(label: label)
                consumer!.consumeField(label: label, value: value)
                fields.append(value)
            }
            consumer!.consumeRow(labels: labels, fields: fields)
            rowsReturned += 1
            (note, position) = io.nextNote(position)
        }
        io.closeCollection()
        return rowsReturned
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

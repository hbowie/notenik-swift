//
//  NoteIndexReader.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class NoteIndexReader: RowImporter {
    
    var consumer:           RowConsumer?
    var workspace:          ScriptWorkspace?
    
    var collection:         NoteCollection?
    
    var indexCollection     = IndexCollection()
    
    var rowCount            = 0

    var labels:             [String] = []
    var fields:             [String] = []
    
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
    func read(fileURL: URL) {
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
        
        labels.append("Initial Letter")
        labels.append("Term")
        labels.append("Lower Case Term")
        labels.append("Term Link")
        labels.append("Page")
        labels.append("Anchor")
        
        var (note, position) = io.firstNote()
        while note != nil {
            if note!.hasTitle() && note!.hasIndex() {
                indexCollection.add(page: note!.title.value, index: note!.index)
            }
            (note, position) = io.nextNote(position)
        }
        io.closeCollection()
        
        for term in indexCollection.list {
            let initialLetter = term.term.prefix(1).uppercased()
            let lowerTerm = term.term.lowercased()
            for ref in term.refs {
                fields = []
                
                consumer!.consumeField(label: labels[0], value: initialLetter)
                fields.append(initialLetter)
                
                consumer!.consumeField(label: labels[1], value: term.term)
                fields.append(term.term)
                
                consumer!.consumeField(label: labels[2], value: lowerTerm)
                fields.append(lowerTerm)
                
                consumer!.consumeField(label: labels[3], value: term.link)
                fields.append(term.link)
                
                consumer!.consumeField(label: labels[4], value: ref.page)
                fields.append(ref.page)
                
                consumer!.consumeField(label: labels[5], value: ref.anchor)
                fields.append(ref.anchor)
                
                consumer!.consumeRow(labels: labels, fields: fields)
            }
        }
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "NoteIndexReader",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
    
}

//
//  NotesExporter.swift
//  Notenik
//
//  Created by Herb Bowie on 7/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class NotesExporter {
    
    let appPrefs = AppPrefs.shared
    
    var tagsToSelect:   TagsValue!
    var tagsToSuppress: TagsValue!
    
    var noteIO: NotenikIO!
    var dict = FieldDictionary()
    var format = NoteFormat.commaSeparated
    var split = false
    var webExt = false
    var destination: URL!
    
    var delimWriter: DelimitedWriter!
    var markup: Markedup!
    
    var authorDef = false
    var workDef = false
    
    var notesExported = 0
    var tagsWritten = 0
    
    /// Initialize the Exporter.
    init() {
        tagsToSelect = TagsValue(appPrefs.tagsToSelect)
        tagsToSuppress = TagsValue(appPrefs.tagsToSuppress)
    }
    
    /// Export the Notes to one of several possible output formats.
    func export(noteIO: NotenikIO,
                       format: NoteFormat,
                       useTagsExportPrefs: Bool,
                       split: Bool,
                       addWebExtensions: Bool,
                       destination: URL) -> Int {
        
        self.noteIO = noteIO
        self.format = format
        self.split = split
        if format == .bookmarks {
            self.split = true
        }
        self.webExt = addWebExtensions
        self.destination = destination
        
        guard noteIO.collection != nil && noteIO.collectionOpen else { return -1 }
        dict = noteIO.collection!.dict
        
        authorDef = dict.contains(LabelConstants.authorCommon)
        workDef = dict.contains(LabelConstants.workTitleCommon)
        
        logNormal("Export requested to \(destination.absoluteString)")
        
        if useTagsExportPrefs {
            tagsToSelect = TagsValue(appPrefs.tagsToSelect)
            tagsToSuppress = TagsValue(appPrefs.tagsToSuppress)
            logNormal("Tags to select: \(tagsToSelect.description)")
            logNormal("Tags to suppress: \(tagsToSuppress.description)")
        } else {
            tagsToSelect = TagsValue()
            tagsToSuppress = TagsValue()
        }
        
        open()
        notesExported = 0
        
        if format == .bookmarks {
            iterateOverTags(io: noteIO)
        } else {
            iterateOverNotes(noteIO: noteIO)
        }
        
        // Now close the writer, which is when the write to disk happens
        let ok = close()
        if ok {
            logNormal("\(notesExported) notes exported")
            return notesExported
        } else {
            logError("Problems closing output export file")
            return -1
        }
    }
    
    /// Open an output file for the export. 
    func open () {
        switch format {
        case .tabDelimited, .commaSeparated:
            delimWriter = DelimitedWriter(destination: destination, format: format)
            delimOpen()
        case .bookmarks:
            markup = Markedup(format: .netscapeBookmarks)
            markup.startDoc(withTitle: "Bookmarks", withCSS: nil)
        default:
            break
        }
    }
    
    /// Open an output delimited text file.
    func delimOpen() {
        
        delimWriter.open()
        
        // Write out column headers
        if split {
            delimWriter.write(value: "Tag")
        }
        for def in dict.list {
            delimWriter.write(value: def.fieldLabel.properForm)
        }
        
        // Now add optional derived fields
        if webExt {
            delimWriter.write(value: "Body as HTML")
            if authorDef {
                delimWriter.write(value: "Author Last Name First")
                delimWriter.write(value: "Author File Name")
                delimWriter.write(value: "Author Wikimedia Page")
            }
            
            if workDef {
                delimWriter.write(value: "Work HTML Line")
                delimWriter.write(value: "Work Rights HTML Line")
            }
        }
        
        // Finish up the heading line
        delimWriter.endLine()
    }
    
    func iterateOverNotes(noteIO: NotenikIO) {
        // Now export each Note
        var (nextNote, position) = noteIO.firstNote()
        while nextNote != nil {
            let note = nextNote!
            
            // Let's see if the next Note meets Tags Selection Criteria
            var noteSelected = true
            if tagsToSelect.tags.count > 0 {
                noteSelected = false
                for noteTag in note.tags.tags {
                    for selTag in tagsToSelect.tags {
                        if noteTag == selTag {
                            noteSelected = true
                        }
                    }
                }
            }
            
            if noteSelected {
                exportSelectedNote(note)
            }
            
            (nextNote, position) = noteIO.nextNote(position)
        }
    }
    
    /// Export a Note that has met the selection criteria. 
    func exportSelectedNote(_ note: Note) {
        
        // Check each tag on the selected note
        let cleanTags = TagsValue()
        for tag in note.tags.tags {
            var tagSelected = true
            for supTag in tagsToSuppress.tags {
                if tag == supTag {
                    tagSelected = false
                }
            }
            if tagSelected {
                cleanTags.tags.append(tag)
            }
        }
        cleanTags.sort()
        
        tagsWritten = 0
        if split {
            for tag in cleanTags.tags {
                writeLine(splitTag: tag.description, cleanTags: cleanTags.description, note: note)
            }
        }
        if tagsWritten == 0 {
            writeLine(splitTag: "", cleanTags: cleanTags.description, note: note)
        }
        
    }
    
    /// Write a single output line containing data from a single Note.
    ///
    /// - Parameters:
    ///   - splitTag: If we're splitting by tag, then the tag to write for this line; otherwise blank.
    ///   - cleanTags: The cleaned tags for this note, with any suppressed tags removed.
    ///   - note: The Note to be written.
    func writeLine(splitTag: String, cleanTags: String, note: Note) {
        if split {
            writeField(value: splitTag)
        }
        for def in dict.list {
            if def.fieldLabel.commonForm == LabelConstants.tagsCommon {
                writeField(value: cleanTags)
            } else {
                writeField(value: note.getFieldAsString(label: def.fieldLabel.commonForm))
            }
        }
        
        if webExt {
            // Now add derived fields
            let code = Markedup(format: .htmlFragment)
            code.append(markdown: note.getFieldAsString(label: LabelConstants.bodyCommon))
            writeField(value: String(describing: code))
            
            if authorDef {
                let author = note.author
                writeField(value: author.lastNameFirst)
                writeField(value: StringUtils.toCommonFileName(author.firstNameFirst))
                writeField(value: StringUtils.wikiMediaPage(author.firstNameFirst))
            }
            
            if workDef {
                
                // Write the Work HTML Line
                var html = Markedup(format: .htmlFragment)
                let workType = note.getFieldAsString(label: LabelConstants.workTypeCommon)
                html.spanConditional(value: workType, klass: "sourcetype", prefix: "the ", suffix: " ")
                let workTitle = note.getFieldAsString(label: LabelConstants.workTitleCommon)
                html.spanConditional(value: workTitle, klass: "majortitle", prefix: "", suffix: "", tag: "cite")
                let pubCity = note.getFieldAsString(label: LabelConstants.pubCityCommon)
                html.spanConditional(value: pubCity, klass: "city", prefix: ", ", suffix: ":")
                let publisher = note.getFieldAsString(label: LabelConstants.publisherCommon)
                html.spanConditional(value: publisher, klass: "publisher", prefix: " ", suffix: "")
                let date = String(describing: note.date)
                html.spanConditional(value: date, klass: "datepublished", prefix: ", ", suffix: "")
                let pages = note.getFieldAsString(label: LabelConstants.workPagesCommon)
                html.spanConditional(value: pages, klass: "pages", prefix: ", pages&nbsp;", suffix: "")
                let workID = note.getFieldAsString(label: LabelConstants.workIDcommon)
                html.spanConditional(value: workID, klass: "isbn", prefix: ", ISBN&nbsp;", suffix: "")
                writeField(value: String(describing: html))
                
                // Write the Work Rights HTML Line
                html = Markedup(format: .htmlFragment)
                let rights = note.getFieldAsString(label: LabelConstants.workRightsCommon)
                var symbol = ""
                if rights.lowercased() == "copyright" {
                    symbol = " &copy;"
                }
                html.spanConditional(value: rights, klass: "rights", prefix: "", suffix: symbol)
                html.spanConditional(value: date, klass: "datepublished", prefix: " ", suffix: "")
                let owner = note.getFieldAsString(label: LabelConstants.workRightsHolderCommon)
                html.spanConditional(value: owner, klass: "rightsowner", prefix: " by ", suffix: "")
                writeField(value: String(describing: html))
            }
        }
        
        // Finish up the line
        endLine()
        tagsWritten += 1
        notesExported += 1
    }
    
    /// Write a single field value to the output line.
    func writeField(value: String) {
        switch format {
        case .tabDelimited:
            delimWriter.write(value: value)
        case .commaSeparated:
            delimWriter.write(value: value)
        default:
            break
        }
    }
    
    /// End an output line containing the data from one Note.
    func endLine() {
        switch format {
        case .tabDelimited, .commaSeparated:
            delimWriter.endLine()
        default:
            break
        }
    }
    
    /// Close the output file, and return result.
    func close() -> Bool {
        switch format {
        case .tabDelimited:
            return delimClose()
        case .commaSeparated:
            return delimClose()
        case .bookmarks:
            return markupClose()
        default:
            break
        }
        return true
    }
    
    /// Close the Delimited Writer
    func delimClose() -> Bool {
        return delimWriter.close()
    }
    
    func iterateOverTags(io: NotenikIO) {
        var depth = 0
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        while tagsNode != nil {
            while depth > iterator.depth {
                markup.decreaseIndent()
                markup.writeLine("</DL><p>")
                depth -= 1
            }
            if tagsNode!.type == .tag {
                markup.writeLine("<DT><H3 FOLDED>\(tagsNode!.tag!)</H3>")
                markup.writeLine("<DL><p>")
                markup.increaseIndent()
            } else if tagsNode!.type == .note {
                guard let note = tagsNode!.note else { break }
                markup.writeLine("<DT><A HREF=\"\(note.link.value)\">\(note.title.value)</A>")
                notesExported += 1
            }
            depth = iterator.depth
            tagsNode = iterator.next()
        }
        while depth > iterator.depth {
            markup.decreaseIndent()
            markup.writeLine("</DL><p>")
            depth -= 1
        }
    }
    
    // Close the markup writer.
    func markupClose() -> Bool {
        markup.finishDoc()
        do {
            try markup.code.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "NotesExporter",
                              level: .error,
                              message: "Problem writing bookmarks file to disk!")
            return false
        }
        return true
    }
    
    /// Log a normal message
    func logNormal(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotesExporter", level: .info, message: msg)
    }
    
    /// Log a normal message
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NotesExporter", level: .error, message: msg)
    }
}

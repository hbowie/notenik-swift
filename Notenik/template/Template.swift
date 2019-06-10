//
//  Template.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A template to be used to create text file output
/// (such as an HTML file) from a Collection of Notes.
class Template {
    
    var util = TemplateUtil()
    var io: NotenikIO = BunchIO()
    
    var recLines         = [TemplateLine]()
    var outerLinesBefore = [TemplateLine]()
    var outerLinesAfter  = [TemplateLine]()
    var endGroupLines    = [TemplateLine]()
    var endLines         = [TemplateLine]()
    
    
    init() {
        
    }
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors.
    func openTemplate(templateURL: URL) -> Bool {
        return util.openTemplate(templateURL: templateURL)
    }
    
    /// Supply the Notenik data to be used with the template.
    ///
    /// - Parameter io: The NotenikIO module to be used, providing access to the data.
    func supplyData(io: NotenikIO) {
        self.io = io
        guard io.collection != nil && io.collectionOpen else { return }
        util.dataFileName = FileName(io.collection!.collectionFullPath)
    }
    
    /// Merge the supplied data with the template to generate output.
    ///
    /// - Returns: True if everything went smoothly, false if problems. 
    func generateOutput() -> Bool {
        
        guard util.templateOK else { return false }
        guard io.collectionOpen else { return false }
        
        recLines = []
        outerLinesBefore = []
        outerLinesAfter = []
        endGroupLines = []
        endLines = []
        
        util.skippingData = false
        util.outputStage = .front
        var line = util.nextTemplateLine()
        let emptyNote = Note(collection: io.collection!)
        while line != nil {
            if util.outputStage == .front {
                line!.generateOutput(note: emptyNote)
            } else if util.outputStage == .loop {
                if line!.command != nil && line!.command! == .nextrec {
                    // Don't need to store the nextrec command line
                } else {
                    recLines.append(line!)
                }
            } else if util.outputStage == .postLoop {
                if line!.command != nil && line!.command! == .loop {
                    processData()
                } else {
                    line!.generateOutput(note: emptyNote)
                }
            }
            line = util.nextTemplateLine()
        }
        util.closeOutput()
        return true
    }
    
    /// Merge that data in the Notes collection with the template lines
    /// between the nextrec and loop commands. 
    func processData() {
        
        var (note, position) = io.firstNote()
        while note != nil {
            for line in recLines {
                line.generateOutput(note: note!)
            }
            (note, position) = io.nextNote(position)
        }
    }
}

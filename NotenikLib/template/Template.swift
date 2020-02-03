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
    var notesList = NotesList()
    var collection = NoteCollection()
    var workspace: ScriptWorkspace?
    
    var loopLines        = [TemplateLine]()
    var outerLinesBefore = [TemplateLine]()
    var outerLinesAfter  = [TemplateLine]()
    var endGroupLines    = [TemplateLine]()
    var endLines         = [TemplateLine]()
    
    
    init() {
        
    }
    
    func setWebRoot(filePath: String) {
        util.setWebRoot(filePath: filePath)
    }
    
    func setWorkspace(_ workspace: ScriptWorkspace) {
        self.workspace = workspace
        util.setWorkspace(workspace)
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
    /// - Parameters:
    ///   - notesList: The list of Notes to be used.
    ///   - dataSource: A path identifying the source of the notes.
    func supplyData(notesList: NotesList, dataSource: String) {
        self.notesList = notesList
        util.dataFileName = FileName(dataSource)
    }
    
    /// Merge the supplied data with the template to generate output.
    ///
    /// - Returns: True if everything went smoothly, false if problems. 
    func generateOutput() -> Bool {
        
        guard util.templateOK else { return false }
        if notesList.count > 0 {
            collection = notesList[0].collection
        } else {
            collection = NoteCollection()
        }
        
        loopLines = []
        outerLinesBefore = []
        outerLinesAfter = []
        endGroupLines = []
        endLines = []
        
        util.skippingData = false
        util.outputStage = .front
        var line = util.nextTemplateLine()
        let emptyNote = Note(collection: collection)
        while line != nil {
            if util.outputStage == .front {
                line!.generateOutput(note: emptyNote)
            } else if util.outputStage == .loop {
                if line!.command != nil && line!.command! == .nextrec {
                    // Don't need to store the nextrec command line
                } else {
                    loopLines.append(line!)
                }
            } else if util.outputStage == .postLoop {
                if line!.command != nil && line!.command! == .loop {
                    processLoop()
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
    func processLoop() {
        
        for note in notesList {
            util.resetGroupBreaks()
            for line in loopLines {
                line.generateOutput(note: note)
            }
        }
    }
}
//
//  ReportRunner.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

public class ReportRunner: NSObject, TemplateOutputSource {
    
    var io: NotenikIO!
    
    var runType: RunType = .unknown
    
    var lowYM = "0000"
    var highYM = "9999"
    
    var displayPrefs = DisplayPrefs.shared
    
    var report: MergeReport!
    
    var queryOutputLauncher: QueryOutputLauncher?
    
    init(io: NotenikIO) {
        self.io = io
    }
    
    public func refreshQuery() {
        switch runType {
        case .calendar:
            runCalendar()
        case .favorites:
            runFavorites()
        case .reportFile:
            _ = runReport()
        case .unknown:
            break
        }
    }
    
    public func runCalendar(lowYM: String, highYM: String) {
        guard io.collectionOpen else { return }
        runType = .calendar
        self.lowYM = lowYM
        self.highYM = highYM
        runCalendar()
    }
    
    private func runCalendar() {
        guard io.collectionOpen else { return }
        let calendar = CalendarMaker(format: .htmlDoc, lowYM: lowYM, highYM: highYM)
        calendar.startCalendar(title: io.collection!.title, prefs: displayPrefs)
        
        var (note, position) = io.firstNote()
        var done = false
        while note != nil && !done {
            done = calendar.nextNote(note!)
            (note, position) = io.nextNote(position)
        }
        
        let html = calendar.finishCalendar()
        
        queryOutputLauncher = QueryOutputLauncher(windowTitle: "Calendar")
        queryOutputLauncher!.supplySource(self)
        queryOutputLauncher!.consumeTemplateOutput(html)
    }
    
    public func runFavorites() {
        guard io.collectionOpen else { return }
        runType = .favorites
        let favsToHTML = FavoritesToHTML(noteIO: io)
        let html = favsToHTML.generate()
        if !html.isEmpty {
            queryOutputLauncher = QueryOutputLauncher(windowTitle: "Favorites")
            queryOutputLauncher!.supplySource(self)
            queryOutputLauncher!.consumeTemplateOutput(html)
        }
    }
    
    public func runReport(_ report: MergeReport) -> Bool {
        guard io.collectionOpen else { return false }
        guard io.collection!.lib.hasAvailable(type: .reports) else { return false }
        runType = .reportFile
        self.report = report
        return runReport()
    }
    
    private func runReport() -> Bool {
        guard report != nil else { return false }
        var ok = false
        let reportsPath = io.collection!.lib.getPath(type: .reports)
        if report.reportType == "tcz" {
            let scriptURL = report.getURL(folderPath: reportsPath)
            if scriptURL != nil {
                ok = runScript(fileURL: scriptURL!)
            }
        } else {
            let templateURL = report.getURL(folderPath: reportsPath)
            ok = runReportWithTemplate(templateURL!)
        }
        return ok
    }
    
    /// Generate and display a report created from a template file.
    private func runReportWithTemplate(_ templateURL: URL) -> Bool {
        guard let collection = io.collection else { return false }
        let template = Template()
        queryOutputLauncher = nil
        let ext = templateURL.pathExtension.lowercased()
        if ext.contains("htm") {
            queryOutputLauncher = QueryOutputLauncher(windowTitle: "Query Output")
            queryOutputLauncher!.supplySource(self)
        }
        var ok = template.openTemplate(templateURL: templateURL)
        if ok {
            template.supplyData(notesList: io.notesList,
                                dataSource: collection.fullPath)
            ok = template.generateOutput(templateOutputConsumer: queryOutputLauncher)
            if ok {
                let textOutURL = template.util.textOutURL
                if textOutURL != nil {
                    NSWorkspace.shared.open(textOutURL!)
                }
            }
        }
        return ok
    }
    
    private func runScript(fileURL: URL) -> Bool {
        let ok = true
        let player = ScriptPlayer()
        let scriptPath = fileURL.path
        queryOutputLauncher = QueryOutputLauncher(windowTitle: "Script Output")
        queryOutputLauncher!.supplySource(self)
        player.playScript(fileName: scriptPath, templateOutputConsumer: queryOutputLauncher)
        return ok
    }
    
    enum RunType {
        case calendar
        case favorites
        case reportFile
        case unknown
    }

}

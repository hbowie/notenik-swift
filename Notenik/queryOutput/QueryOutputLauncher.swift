//
//  QueryOutputLauncher.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/22.
//
//  Copyright © 2022 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// Displays the output HTML from a query in a new window.
public class QueryOutputLauncher: NSObject, TemplateOutputConsumer {

    var source: TemplateOutputSource?
    
    let queryOutputStoryboard:     NSStoryboard = NSStoryboard(name: "QueryOutput", bundle: nil)
    
    var windowTitle = ""
    
    init(windowTitle: String = "Query Output") {
        super.init()
        self.windowTitle = windowTitle
    }
    
    public func supplySource(_ source: NotenikLib.TemplateOutputSource) {
        self.source = source
    }
    
    /// Consume output from Merge Template, per TemplateOutputConsumer protocol.
    public func consumeTemplateOutput(_ templateOutput: String) {
        
        guard !templateOutput.isEmpty else { return }
        
        guard let queryOutputWC = self.queryOutputStoryboard.instantiateController(withIdentifier: "queryOutputWC") as? QueryOutputWindowController else {
            return
        }
        queryOutputWC.window!.title = windowTitle
        if source != nil {
            queryOutputWC.supplySource(source!)
        }
        queryOutputWC.showWindow(self)
        applyNumbers(passedWindow: queryOutputWC.window)
        if let vc = queryOutputWC.contentViewController as? QueryOutputViewController {
            vc.windowTitle = windowTitle
            vc.loadHTMLString(templateOutput)
        }

    }
    
    func applyNumbers(passedWindow: NSWindow?) {
        guard let window = passedWindow else { return }
        let windowStr = AppPrefs.shared.queryOutputWindowNumbers
        guard !windowStr.isEmpty else { return }
        let numbers = windowStr.components(separatedBy: ";")
        guard numbers.count >= 4 else {
            return
        }
        var x = Double(numbers[0])
        var y = Double(numbers[1])
        var width = Double(numbers[2])
        var height = Double(numbers[3])
        guard x != nil && y != nil && width != nil && height != nil  else {
            return
        }
        
        guard let mainScreen = NSScreen.main else { return }
        let visibleFrame = mainScreen.visibleFrame
        if x! < visibleFrame.minX {
            x = visibleFrame.minX
        }
        guard x! <= visibleFrame.maxX else { return }
        if (x! + width!) > visibleFrame.maxX {
            width = visibleFrame.maxX - x!
        }
        guard width! >= 300 else { return }
        if (y! < visibleFrame.minY) {
            y = visibleFrame.minY
        }
        if (y! + height!) > visibleFrame.maxY {
            height = visibleFrame.maxY - y!
        }
        
        let frame = NSRect(x: x!, y: y!, width: width!, height: height!)
        window.setFrame(frame, display: true)
    }

}

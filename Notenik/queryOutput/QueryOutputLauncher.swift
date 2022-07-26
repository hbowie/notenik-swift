//
//  QueryOutputLauncher.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// Displays the output HTML from a query in a new window.
public class QueryOutputLauncher: NSObject, TemplateOutputConsumer {
    
    let queryOutputStoryboard:     NSStoryboard = NSStoryboard(name: "QueryOutput", bundle: nil)
    
    /// Consume output from Merge Template, per TemplateOutputConsumer protocol.
    public func consumeTemplateOutput(_ templateOutput: String) {
        guard !templateOutput.isEmpty else { return }
        
        if let queryOutputWC = self.queryOutputStoryboard.instantiateController(withIdentifier: "queryOutputWC") as? QueryOutputWindowController {
            queryOutputWC.showWindow(self)
            if let vc = queryOutputWC.contentViewController as? QueryOutputViewController {
                vc.loadHTMLString(templateOutput)
            }
        } 
    }

}

//
//  QueryOutputWindowController.swift
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

class QueryOutputWindowController: NSWindowController {
    
    var vc: QueryOutputViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is QueryOutputViewController {
            vc = contentViewController as? QueryOutputViewController
            // vc!.window = self
        }
    }
    
    public func supplySource(_ source: TemplateOutputSource) {
        if vc != nil {
            vc!.supplySource(source)
        }
    }

}

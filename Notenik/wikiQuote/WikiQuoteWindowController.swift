//
//  WikiQuoteWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 9/23/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class WikiQuoteWindowController: NSWindowController {
    
    var wikiQuoteViewController: WikiQuoteViewController?
    
    var io: NotenikIO? {
        get {
            return wikiQuoteViewController?.io
        }
        set {
            if let vc = wikiQuoteViewController {
                vc.io = newValue
            }
        }
    }
    
    var cwc: CollectionWindowController? {
        get {
            return wikiQuoteViewController?.cwc
        }
        set {
            if let vc = wikiQuoteViewController {
                vc.cwc = newValue
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    
        if contentViewController != nil && contentViewController is WikiQuoteViewController {
            wikiQuoteViewController = contentViewController as? WikiQuoteViewController
            wikiQuoteViewController!.window = self
        }
    }

}

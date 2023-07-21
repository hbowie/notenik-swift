//
//  ScriptWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Controls the Scripter Window. 
class ScriptWindowController: NSWindowController {
    
    var scriptViewController: ScriptViewController?
    
    var scriptView: NSView?
    
    var splitViewController: NoteSplitViewController?
    
    var collectionItem: NSSplitViewItem?
    var collectionTabs: NSTabViewController?
    var listItem: NSTabViewItem?
    var listVC: NoteListViewController?
    var tagsItem: NSTabViewItem?
    var tagsVC: NoteTagsViewController?
    
    var noteItem: NSSplitViewItem?
    var noteTabs: NoteTabsViewController?
    var displayItem: NSTabViewItem?
    var displayVC: NoteDisplayViewController?
    var editItem: NSTabViewItem?
    var editVC: NoteEditViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is ScriptViewController {
            scriptViewController = contentViewController as? ScriptViewController
            scriptViewController!.window = self
        }
        if scriptViewController != nil {
            scriptView = scriptViewController!.view
        }
    }
    
    func scriptOpenInput(_ scriptURL: URL, goNow: Bool = false) {
        if scriptViewController != nil {
            scriptViewController!.scriptOpenInput(scriptURL, goNow: goNow)
        }
    }

}

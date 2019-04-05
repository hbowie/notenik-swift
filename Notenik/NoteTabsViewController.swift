//
//  NoteTabsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 3/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Controls the tabs for the display and edit views for a single note
class NoteTabsViewController: NSTabViewController {
    
    var collectionWindowController: CollectionWindowController?
    
    /// Get or Set the Window Controller
    var window: CollectionWindowController? {
        get {
            return collectionWindowController
        }
        set {
            collectionWindowController = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        
        guard tabViewItem != nil else { return }
        guard window != nil else { return }
        
        if tabViewItem!.label != "Edit" {
            window!.modIfChanged()
        }
    }
    
}

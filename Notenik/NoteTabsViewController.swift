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
    
    /// If collection is read-only, then don't allow Edit tab to be selected
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        let superResponse = super.tabView(tabView, shouldSelect: tabViewItem)
        guard tabViewItem != nil else { return superResponse }
        guard window != nil else { return superResponse }
        guard tabViewItem!.label == "Edit" else { return superResponse }
        guard window!.io != nil else { return superResponse }
        guard let collection = window!.io!.collection else { return superResponse }
        if collection.readOnly {
            return false
        } else {
            return superResponse
        }
    }
    
    /// If we're leaving the Edit Tab, then check for any changes made by the user
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        guard tabViewItem != nil else { return }
        guard window != nil else { return }
        if tabViewItem!.label != "Edit" && !window!.pendingMod  {
            _ = window!.modIfChanged()
        }
    }
    
}

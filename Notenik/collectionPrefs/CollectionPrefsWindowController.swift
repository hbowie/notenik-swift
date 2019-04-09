//
//  TemplateWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CollectionPrefsWindowController: NSWindowController {
    
    var collectionPrefsViewController: CollectionPrefsViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is CollectionPrefsViewController {
            collectionPrefsViewController = contentViewController as? CollectionPrefsViewController
        }
    }
    
    /// Pass needed info from the Collection Juggler
    func passJugglerInfo(owner: CollectionPrefsOwner, collection: NoteCollection) {
        guard collectionPrefsViewController != nil else {
            print ("Passing Juggler Info but collectionPrefsViewController is nil!")
            return
        }
        collectionPrefsViewController!.passJugglerInfo(owner: owner, collection: collection, window: self)
    }

}

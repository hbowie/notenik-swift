//
//  CollectionPrefsWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

class CollectionPrefsWindowController: NSWindowController {
    
    var collectionPrefsViewController: CollectionPrefsViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is CollectionPrefsViewController {
            collectionPrefsViewController = contentViewController as? CollectionPrefsViewController
        }
    }
    
    
    
    /// Pass needed info from the Collection Prefs Requestor
    func passCollectionPrefsRequesterInfo(collection: NoteCollection,
                                          defsRemoved: DefsRemoved) {
        guard collectionPrefsViewController != nil else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectionPrefsWindowController",
                              level: .fault,
                              message: "CollectionPrefsWindowController passsing Requester Info but view controller is missing")
            return
        }
        collectionPrefsViewController!.passCollectionPrefsRequesterInfo(collection: collection,
                                              window: self,
                                              defsRemoved: defsRemoved)
    }

}

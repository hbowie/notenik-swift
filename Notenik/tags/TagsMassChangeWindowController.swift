//
//  TagsMassChangeWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/22/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class TagsMassChangeWindowController: NSWindowController {
    
    var tagsMassChangeViewController: TagsMassChangeViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is TagsMassChangeViewController {
            tagsMassChangeViewController = contentViewController as? TagsMassChangeViewController
            tagsMassChangeViewController!.window = self
        }
    }
    
    func passCollectionInfo(io: NotenikIO, collectionWC: CollectionWindowController) {
        tagsMassChangeViewController!.passCollectionInfo(io: io, collectionWC: collectionWC)
    }

}

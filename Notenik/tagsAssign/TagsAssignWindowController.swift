//
//  TagsAssignWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 10/18/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class TagsAssignWindowController: NSWindowController {
    
    var tagsAssignViewController: TagsAssignViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is TagsAssignViewController {
            tagsAssignViewController = contentViewController as? TagsAssignViewController
            tagsAssignViewController!.window = self
        }
    }
    
    func passCollectionInfo(io: NotenikIO, collectionWC: CollectionWindowController) {
        tagsAssignViewController!.passCollectionInfo(io: io, collectionWC: collectionWC)
    }

}

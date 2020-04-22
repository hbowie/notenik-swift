//
//  CollectorWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/20/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

class CollectorWindowController: NSWindowController {
    
    var collectorViewController: CollectorViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is CollectorViewController {
            collectorViewController = contentViewController as? CollectorViewController
        }
    }
    
    /// Pass needed info from the Collector Requestor
    func passCollectorRequesterInfo(tree: CollectorTree) {
        guard collectorViewController != nil else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "CollectorWindowController",
                              level: .fault,
                              message: "CollectorWindowController passing Requester Info but view controller is missing")
            return
        }
        collectorViewController!.passCollectorRequesterInfo(tree: tree)
    }

}

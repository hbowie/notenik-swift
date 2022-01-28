//
//  LinkCleanerWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class LinkCleanerWindowController: NSWindowController {
    
    var linkCleanerViewController: LinkCleanerViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        if contentViewController != nil && contentViewController is LinkCleanerViewController {
            linkCleanerViewController = contentViewController as? LinkCleanerViewController
            linkCleanerViewController?.windowController = self
        }
    }
    
    func passCollectionWindow(_ collectionWC: CollectionWindowController) {
        if let vc = linkCleanerViewController {
            vc.passCollectionWindow(collectionWC)
        }
    }

}

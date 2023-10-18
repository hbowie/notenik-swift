//
//  TagsAssignViewController.swift
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

class TagsAssignViewController: NSViewController {
    
    var window: TagsAssignWindowController?
    
    var io: NotenikIO?
    var collectionWC: CollectionWindowController?
    
    @IBOutlet var tagToAssignTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppPrefsCocoa.shared.setTextEditingFont(object: tagToAssignTextField)
    }
    
    func passCollectionInfo(io: NotenikIO, collectionWC: CollectionWindowController) {
        self.io = io
        self.collectionWC = collectionWC
    }
    
    @IBAction func cancelAssignment(_ sender: Any) {
        window!.close()
    }
    
    @IBAction func proceedWithAssignment(_ sender: Any) {
        guard collectionWC != nil else { return }
        collectionWC!.tagAssignNow(to: tagToAssignTextField.stringValue,
                                   vc: self)
    }
    
}

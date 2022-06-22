//
//  TagsMassChangeViewController.swift
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

class TagsMassChangeViewController: NSViewController {
    
    var window: TagsMassChangeWindowController?
    
    var io: NotenikIO?
    var collectionWC: CollectionWindowController?
    
    var tagsTokenDelegate: TagsTokenDelegate?

    @IBOutlet var existingTagsTokenField: NSTokenField!
    @IBOutlet var replaceTagsTokenField: NSTokenField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppPrefsCocoa.shared.setTextEditingFont(object: existingTagsTokenField)
        existingTagsTokenField.tokenizingCharacterSet = CharacterSet([",",";"])
        
        AppPrefsCocoa.shared.setTextEditingFont(object: replaceTagsTokenField)
        replaceTagsTokenField.tokenizingCharacterSet = CharacterSet([",",";"])
        
    }
    
    func passCollectionInfo(io: NotenikIO, collectionWC: CollectionWindowController) {
        self.io = io
        self.collectionWC = collectionWC
        tagsTokenDelegate = TagsTokenDelegate(tagsPickList: io.pickLists.tagsPickList)
        existingTagsTokenField.delegate = tagsTokenDelegate
        replaceTagsTokenField.delegate = tagsTokenDelegate
    }
    
    @IBAction func okAction(_ sender: Any) {
        guard collectionWC != nil else { return }
        collectionWC!.tagsMassChangeNow(from: existingTagsTokenField.stringValue,
                                        to: replaceTagsTokenField.stringValue,
                                        vc: self)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        window!.close()
    }
}

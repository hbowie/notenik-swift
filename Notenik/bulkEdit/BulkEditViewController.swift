//
//  BulkEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/26/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class BulkEditViewController: NSViewController {
    
    var window: BulkEditWindowController?
    
    var io: NotenikIO?
    var collectionWC: CollectionWindowController?
    var selNotes: [Note] = []

    @IBOutlet var rangeDescription: NSTextField!
    
    @IBOutlet var fieldSelector: NSPopUpButton!
    
    @IBOutlet var valueToAssign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func passRequestInfo(io: NotenikIO, 
                            collectionWC: CollectionWindowController,
                            selNotes: [Note]) {
        self.io = io
        self.collectionWC = collectionWC
        self.selNotes = selNotes
        
        guard let collection = io.collection else { return }
        if selNotes.isEmpty {
            rangeDescription.stringValue = "No Notes Selected"
        } else if selNotes.count == 1 {
            rangeDescription.stringValue = "There is 1 Note to be edited, titled '\(selNotes[0].title.value)'"
        } else {
            rangeDescription.stringValue = "There are \(selNotes.count) Notes to be edited, including one titled '\(selNotes[0].title.value)'"
        }
        
        fieldSelector.removeAllItems()
        for def in collection.dict.list {
            if !def.fieldType.userEditable { continue }
            if def.fieldType.isTextBlock { continue }
            switch def.fieldType.typeString {
            case NotenikConstants.titleCommon:
                break
            case NotenikConstants.linkCommon:
                break
            default:
                fieldSelector.addItem(withTitle: def.fieldLabel.properForm)
            }
        }
        
        if fieldSelector.numberOfItems > 0 {
            fieldSelector.selectItem(at: 0)
        }
        
        // tagsTokenDelegate = TagsTokenDelegate(tagsPickList: io.pickLists.tagsPickList)
        // existingTagsTokenField.delegate = tagsTokenDelegate
        // replaceTagsTokenField.delegate = tagsTokenDelegate
    }
    
    @IBAction func cancelActions(_ sender: Any) {
        window!.close()
    }
    
    @IBAction func okToProceed(_ sender: Any) {
        collectionWC!.bulkEditOK(fieldSelected: fieldSelector.titleOfSelectedItem!,
                                 valueToAssign: valueToAssign.stringValue,
                                 notes: selNotes,
                                 vc: self)
    }
}

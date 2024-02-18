//
//  IdPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/10/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

import NotenikUtils

class IdPrefsViewController: NSViewController {
    
    let application = NSApplication.shared
    
    let noField = " - none -"

    @IBOutlet var rulePopup: NSPopUpButton!
    
    @IBOutlet var fieldPopup: NSPopUpButton!
    
    @IBOutlet var textRulePopup: NSPopUpButton!
    
    @IBOutlet var textIdSep: NSTextField!
    
    @IBOutlet var msgText: NSTextField!
    
    @IBOutlet var collectionPath: NSPathControl!
    
    var windowController: IdPrefsWindowController!
    var collection: NoteCollection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rulePopup.removeAllItems()
        textRulePopup.removeAllItems()
        for rule in NoteIdentifierRule.allCases {
            rulePopup.addItem(withTitle: rule.rawValue)
            textRulePopup.addItem(withTitle: rule.rawValue)
        }
        msgText.stringValue = ""
    }
    
    func passIdPrefsRequesterInfo(collection: NoteCollection,
                                  window: IdPrefsWindowController) {
        
        self.windowController = window
        self.collection = collection
        
        rulePopup.selectItem(withTitle: collection.noteIdentifier.uniqueIdRule.rawValue)
        textRulePopup.selectItem(withTitle: collection.noteIdentifier.textIdRule.rawValue)
        textIdSep.stringValue = collection.noteIdentifier.textIdSep
        
        fieldPopup.removeAllItems()
        fieldPopup.addItem(withTitle: noField)
        fieldPopup.selectItem(at: 0)
        let commonAux = StringUtils.toCommon(collection.noteIdentifier.noteIdAuxField)
        for def in collection.dict.list {
            switch def.fieldType.typeString {
            case NotenikConstants.titleCommon:
                break
            case NotenikConstants.longTextType:
                break
            case NotenikConstants.codeCommon:
                break
            case NotenikConstants.teaserCommon:
                break
            case NotenikConstants.bodyCommon:
                break
            default:
                fieldPopup.addItem(withTitle: def.fieldLabel.properForm)
                if commonAux == def.fieldLabel.commonForm {
                    fieldPopup.selectItem(at: fieldPopup.numberOfItems - 1)
                }
            }
        }
                             
        collectionPath.url = collection.fullPathURL
        let collectionFileName = FileName(collection.fullPath)
        
        // The following nonsense attempts to work around a bug
        // that truncates part of the last folder name if it
        // contains a space.
        var i = collectionFileName.folders.count - 1
        var j = collectionPath.pathItems.count - 1
        while i >= 0 && j > 0 {
            let pathItem = collectionPath.pathItems[j]
            pathItem.title = collectionFileName.folders[i]
            i -= 1
            j -= 1
        }
    }
    
    @IBAction func cancelChanges(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        windowController!.close()
    }
    
    @IBAction func okToProceed(_ sender: Any) {
        
        guard let noteIdRuleStr = rulePopup.selectedItem?.title else {
            msgText.stringValue = "No rule selected"
            return
        }
        
        guard let noteIdRule = NoteIdentifierRule(rawValue: noteIdRuleStr) else {
            msgText.stringValue = "Invalid rule selection"
            return
        }
        
        var auxNeeded = false
        switch noteIdRule {
        case .titleOnly:
            auxNeeded = false
        case .auxOnly:
            auxNeeded = true
        case .titleAfterAux:
            auxNeeded = true
        case .titleBeforeAux:
            auxNeeded = true
        }
        
        if !auxNeeded && fieldPopup.indexOfSelectedItem > 0 {
            msgText.stringValue = "You cannot select an auxiliary field for this Note ID rule"
            return
        }
        
        if auxNeeded && fieldPopup.indexOfSelectedItem == 0 {
            msgText.stringValue = "You must select an auxiliary field for this Note ID rule"
            return
        }
        
        msgText.stringValue = ""
        
        if let noteIdRule = NoteIdentifierRule(rawValue: rulePopup.selectedItem!.title) {
            collection.noteIdentifier.uniqueIdRule = noteIdRule
        }
        collection.noteIdentifier.noteIdAuxField = fieldPopup.selectedItem!.title
        if let textIdRule = NoteIdentifierRule(rawValue: textRulePopup.selectedItem!.title) {
            collection.noteIdentifier.textIdRule = textIdRule
        }
        collection.noteIdentifier.textIdSep = textIdSep.stringValue
        
        application.stopModal(withCode: .OK)
        windowController!.close()
    }
    
}

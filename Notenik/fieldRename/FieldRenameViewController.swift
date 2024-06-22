//
//  FieldRenameViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/11/23.
//  Copyright © 2023 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class FieldRenameViewController: NSViewController, NSComboBoxDataSource {
    
    var window: FieldRenameWindowController!
    
    var cwc: CollectionWindowController?
    
    @IBOutlet var actionPopup: NSPopUpButton!

    @IBOutlet var existingFieldLabelCombo: NSComboBox!
    
    @IBOutlet var existingFieldTypeLabel: NSTextField!
    
    @IBOutlet var newFieldLabelText: NSTextField!
    
    @IBOutlet var newFieldTypeCombo: NSComboBox!
    
    @IBOutlet var typeConfigText: NSTextField!
    
    @IBOutlet var msgText: NSTextField!
    
    @IBOutlet var defaultText: NSTextField!
    
    var _io: NotenikIO?
    var collection = NoteCollection()
    var dict: FieldDictionary = FieldDictionary()
    
    var fieldTypes: [String] = []
    
    var parms: FieldRenameParms = FieldRenameParms()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        existingFieldLabelCombo.usesDataSource = true
        existingFieldLabelCombo.dataSource = self
        existingFieldTypeLabel.stringValue = ""
        
        newFieldLabelText.stringValue = ""
        newFieldTypeCombo.usesDataSource = true
        newFieldTypeCombo.dataSource = self
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Collection setup.
    //
    // -----------------------------------------------------------
    
    var io: NotenikIO? {
        get {
            return _io
        }
        set {
            _io = newValue
            if _io != nil && _io!.collection != nil {
                collection = _io!.collection!
                dict = collection.dict
            } else {
                collection = NoteCollection()
                dict = FieldDictionary()
            }
            loadExistingFieldLabels()
            loadNewFieldTypeCombo()
            msgText.stringValue = ""
        }
    }
    
    func loadExistingFieldLabels() {
        existingFieldLabelCombo.reloadData()
    }
    
    func loadNewFieldTypeCombo() {
        fieldTypes = []
        for fieldType in collection.typeCatalog.fieldTypes {
            fieldTypes.append(fieldType.typeString)
        }
        fieldTypes.sort()
        newFieldTypeCombo.reloadData()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Respond to user actions (other than combo box actions).
    //
    // -----------------------------------------------------------
    
    @IBAction func selectAction(_ sender: Any) {
        if let fa = FieldRenameAction(rawValue: actionPopup.indexOfSelectedItem) {
            parms.action = fa
        }
        msgText.stringValue = ""
        if parms.add {
            window.window?.makeFirstResponder(newFieldLabelText)
        }
    }
    
    /// Respond to user selection of an existing field label.
    @IBAction func existingFieldLabelAction(_ sender: Any) {
        msgText.stringValue = ""
        let selIx = existingFieldLabelCombo.indexOfSelectedItem
        if selIx >= 0 && selIx < dict.list.count {
            let typeString = dict.list[selIx].fieldType.typeString
            existingFieldTypeLabel.stringValue = typeString
            let typeIx = indexForType(typeString)
            if parms.action != .remove && typeIx != NSNotFound {
                newFieldTypeCombo.selectItem(at: typeIx)
            }
            let oldDef = dict.list[selIx]
            typeConfigText.stringValue = oldDef.extractTypeConfig(collection: collection)
        } else {
            existingFieldTypeLabel.stringValue = ""
        }
    }
    
    @IBAction func newFieldLabelAction(_ sender: NSTextField) {
        msgText.stringValue = ""
        parms.newFieldLabel = sender.stringValue
        guard !parms.newFieldLabel.isEmpty else { return }
        let label = FieldLabel(parms.newFieldLabel)
        if parms.add {
            let suggestedType = collection.typeCatalog.assignType(label: label, type: nil)
            let suggestedTypeStr = suggestedType.typeString
            if !suggestedTypeStr.isEmpty {
                let typeIx = indexForType(suggestedTypeStr)
                if typeIx != NSNotFound {
                    newFieldTypeCombo.selectItem(at: typeIx)
                    msgText.stringValue = "New field type of \(suggestedTypeStr) has been inferred"
                }
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        window.close()
    }
    
    /// Attempt to perform requested action.
    @IBAction func okAction(_ sender: Any) {
        
        msgText.stringValue = ""
        
        if let fa = FieldRenameAction(rawValue: actionPopup.indexOfSelectedItem) {
            parms.action = fa
        } else {
            msgText.stringValue = "Invalid Field Action"
            return
        }
        
        parms.newFieldLabel = newFieldLabelText.stringValue
        let typeIx = newFieldTypeCombo.indexOfSelectedItem
        if typeIx >= 0 && typeIx < newFieldTypeCombo.numberOfItems {
            parms.newFieldType = fieldTypes[newFieldTypeCombo.indexOfSelectedItem]
        } else {
            parms.newFieldType = ""
        }
        parms.newFieldDefault = defaultText.stringValue
        
        switch parms.action {
        case .rename:
            
            // Check Existing Field Label
            let selIx = existingFieldLabelCombo.indexOfSelectedItem
            if selIx < 0 || selIx >= dict.list.count {
                msgText.stringValue = "You must first select an existing field label"
                return
            }
            parms.existingFieldLabel = dict.list[selIx].fieldLabel.properForm
            
            let typeString = dict.list[selIx].fieldType.typeString
            existingFieldTypeLabel.stringValue = typeString
            
            
            if typeString == NotenikConstants.titleCommon && parms.newFieldType != NotenikConstants.titleCommon {
                msgText.stringValue = "The Title field may not be renamed to a field type other than title"
                return
            }
            if typeString == NotenikConstants.bodyCommon && parms.newFieldType != NotenikConstants.bodyCommon {
                msgText.stringValue = "The Body field may not be renamed to a field type other than body"
                return
            }
            
            // Check New Field Label
            let msg = checkNewFieldLabel()
            if !msg.isEmpty {
                msgText.stringValue = msg
                return
            }
            
        case .add:
            
            // Check New Field Label
            let msg = checkNewFieldLabel()
            if !msg.isEmpty {
                msgText.stringValue = msg
                return
            }
            
        case .remove:
            
            // Check Existing Field Label
            let selIx = existingFieldLabelCombo.indexOfSelectedItem
            if selIx < 0 || selIx >= dict.list.count {
                msgText.stringValue = "You must first select an existing field label"
                return
            }
            parms.existingFieldLabel = dict.list[selIx].fieldLabel.properForm
            
            let typeString = dict.list[selIx].fieldType.typeString
            existingFieldTypeLabel.stringValue = typeString
            if typeString == NotenikConstants.titleCommon {
                msgText.stringValue = "The Title field may not be removed"
                return
            }
            if typeString == NotenikConstants.bodyCommon {
                msgText.stringValue = "The Body field may not be removed"
                return
            }
        }
            
        if cwc != nil {
            cwc!.renameAddRemoveNow(parms: parms, vc: self)
        }
        
    }
    
    /// Ensure we have a workable new field label.
    func checkNewFieldLabel() -> String {
        if parms.newFieldLabel.isEmpty {
            return "New field label must be entered"
        }
        if parms.newFieldLabel.count > 48 {
            return "A field label may not be longer than 48 characters"
        }
        if dict.contains(parms.newFieldLabel) {
            return "A field with this label is already defined"
        }
        return ""
    }
    
    
    // -----------------------------------------------------------
    //
    // MARK: Support for NSComboBoxDataSource
    //
    // -----------------------------------------------------------
    
    /// Returns the number of items that the data source manages for the combo box
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox == existingFieldLabelCombo {
            return dict.list.count
        } else if comboBox == newFieldTypeCombo {
            return fieldTypes.count
        } else {
            return 0
        }
    }
        
    /// Returns the object that corresponds to the item at the specified index in the combo box
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox == existingFieldLabelCombo {
            return dict.list[index].fieldLabel.properForm
        } else if comboBox == newFieldTypeCombo {
            return fieldTypes[index]
        } else {
            return ""
        }
    }
    
    /// Returns the first item from the pop-up list that starts with the text the user has typed.
    func comboBox(_ comboBox: NSComboBox, completedString: String) -> String? {
        if comboBox == existingFieldLabelCombo {
            let completedLower = completedString.lowercased()
            for field in dict.list {
                if field.fieldLabel.commonForm.hasPrefix(completedLower) {
                    return field.fieldLabel.properForm
                }
            }
            return nil
        } else if comboBox == newFieldTypeCombo {
            for fieldType in fieldTypes {
                if fieldType.hasPrefix(completedString) {
                    return fieldType
                }
            }
            return nil
        } else {
            return nil
        }
    }
    
    /// Returns the index of the combo box item matching the specified string.
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue: String) -> Int {
        if comboBox == existingFieldLabelCombo {
            var i = 0
            for field in dict.list {
                if field.fieldLabel.properForm == indexOfItemWithStringValue || field.fieldLabel.commonForm == indexOfItemWithStringValue {
                    return i
                } else {
                    i += 1
                }
            }
            return NSNotFound
        } else if comboBox == newFieldTypeCombo {
            return indexForType(indexOfItemWithStringValue)
        } else {
            return NSNotFound
        }
    }
    
    func indexForType(_ desiredFieldType: String) -> Int {
        var i = 0
        for fieldType in fieldTypes {
            if fieldType == desiredFieldType {
                return i
            } else {
                i += 1
            }
        }
        return NSNotFound
    }

}

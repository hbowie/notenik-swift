//
//  ImportViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class ImportViewController: NSViewController {
    
    var window: ImportWindowController!
    
    var collectionWC: CollectionWindowController?
    
    var io: NotenikIO? {
        get {
            return _io
        }
        set {
            _io = newValue
        }
    }
    var _io: NotenikIO?

    @IBOutlet var fieldsPopup: NSPopUpButton!
    
    @IBOutlet var rowsPopup: NSPopUpButton!
    
    @IBOutlet var consolidateLookupsCkBox: NSButtonCell!
    
    var importParms = ImportParms()
    
    /// Perform any initial view setup needed.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func userSaysCancel(_ sender: Any) {
        importParms.userOkToSettings = false
        finishUp()
    }
    
    @IBAction func userSaysOK(_ sender: Any) {
        importParms.userOkToSettings = true
        
        if let cpStr = fieldsPopup.titleOfSelectedItem {
            if let cp = ImportParms.ColumnParm(rawValue: cpStr) {
                importParms.columnParm = cp
            }
        }
        
        if let rpStr = rowsPopup.titleOfSelectedItem {
            if let rp = ImportParms.RowParm(rawValue: rpStr) {
                importParms.rowParm = rp
            }
        }
        
        importParms.consolidateLookups = (consolidateLookupsCkBox.state == .on)
        
        finishUp()
    }
    
    func finishUp() {
        if let cwc = collectionWC {
            cwc.importSettingsObtained()
        }
        window.close()
    }
    
}

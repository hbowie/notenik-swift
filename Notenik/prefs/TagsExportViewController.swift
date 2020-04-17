//
//  TagsExportViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class TagsExportViewController: NSViewController, PrefsTabVC {

    let appPrefs = AppPrefs.shared
    
    var tagsTokenDelegate: TagsTokenDelegate!
    
    @IBOutlet var tagsToSelect: NSTokenField!
    
    @IBOutlet var tagsToSuppress: NSTokenField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tagsToSelect.tokenizingCharacterSet = CharacterSet([",",";"])
        tagsToSuppress.tokenizingCharacterSet = CharacterSet([",",";"])
        
        tagsToSelect.stringValue = appPrefs.tagsToSelect
        tagsToSuppress.stringValue = appPrefs.tagsToSuppress
        
        tagsTokenDelegate = TagsTokenDelegate(tagsPickList: appPrefs.pickLists.tagsPickList)
        tagsToSelect.delegate = tagsTokenDelegate
        tagsToSuppress.delegate = tagsTokenDelegate
    }
    
    @IBAction func tagsToSelectAction(_ sender: Any) {
        appPrefs.tagsToSelect = tagsToSelect.stringValue
    }
    
    @IBAction func tagsToSuppressAction(_ sender: Any) {
        appPrefs.tagsToSuppress = tagsToSuppress.stringValue
    }
    
    /// Called when the user is leaving this tab for another one.
    func leavingTab() {
        saveUserInput()
    }
    
    @IBAction func tagsExportOK(_ sender: Any) {
        saveUserInput()
        self.view.window!.close()
    }
    
    func saveUserInput() {
        appPrefs.tagsToSelect = tagsToSelect.stringValue
        appPrefs.tagsToSuppress = tagsToSuppress.stringValue
    }
    
}

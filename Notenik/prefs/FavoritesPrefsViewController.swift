//
//  FavoritesPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/18/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class FavoritesPrefsViewController: NSViewController, PrefsTabVC {
    
    let prefs = AppPrefs.shared
    
    @IBOutlet var columnsTextField: NSTextField!
    @IBOutlet var columnsSlider: NSSlider!
    
    @IBOutlet var rowsTextField: NSTextField!
    @IBOutlet var rowsSlider: NSSlider!
    
    @IBOutlet var columnWidth: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let columns = prefs.favoritesColumns
        columnsTextField.stringValue = "\(columns)"
        columnsSlider.integerValue = columns
        
        let rows = prefs.favoritesRows
        rowsTextField.stringValue = "\(rows)"
        rowsSlider.integerValue = rows
        
        columnWidth.stringValue = prefs.favoritesColumnWidth
    }
    
    @IBAction func columnsSliderChanged(_ sender: Any) {
        let columns = columnsSlider.integerValue
        columnsTextField.stringValue = "\(columns)"
        prefs.favoritesColumns = columns
    }
    
    @IBAction func rowsSliderChanged(_ sender: Any) {
        let rows = rowsSlider.integerValue
        rowsTextField.stringValue = "\(rows)"
        prefs.favoritesRows = rows
    }
    
    @IBAction func columnWidthChanged(_ sender: Any) {
        prefs.favoritesColumnWidth = columnWidth.stringValue
    }
    
    /// Called when the user is leaving this tab for another one.
    func leavingTab() {
        saveUserInput()
    }
    
    @IBAction func favoritesPrefsOK(_ sender: Any) {
        saveUserInput()
        self.view.window!.close()
    }
    
    func saveUserInput() {
        prefs.favoritesColumnWidth = columnWidth.stringValue
    }
    
}

//
//  StatusView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/16/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class StatusView: MacEditView {
    
    var config:     StatusValueConfig!
    var dataSource: StatusDataSource!
    var combo:      NSComboBox!
    
    var view: NSView {
        return combo
    }
    
    func setToDefaultValue() {
        if config.defaultIndex >= 0 {
            text = config.get(config.defaultIndex)
        }
    }
    
    var text: String {
        get {
            return config.normalize(str: combo.stringValue, withDigit: true)
        }
        set {
            let (_, label) = config.match(newValue)
            combo.stringValue = label
        }
    }
    
    init(config: StatusValueConfig) {
        self.config = config
        dataSource = StatusDataSource(config: config)
        buildView()
    }
    
    func buildView() {
        
        // Set up the Combo Box control
        combo = NSComboBox()
        combo.completes = true
        combo.usesDataSource = true
        combo.dataSource = dataSource
        AppPrefsCocoa.shared.setTextEditingFont(object: combo)
    }
    
    /// Close the note by selecting the last status value in the list
    func close() {
        let highValue = config.get(config.highIndex)
        combo.stringValue = highValue
    }
}

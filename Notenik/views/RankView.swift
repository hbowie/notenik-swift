//
//  RankView.swift
//  Notenik
//
//  Created by Herb Bowie on 10/24/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class RankView: MacEditView {
    
    var config:     RankValueConfig!
    var dataSource: RankDataSource!
    var combo:      NSComboBox!
    
    var view: NSView {
        return combo
    }
    
    init(config: RankValueConfig) {
        self.config = config
        dataSource = RankDataSource(config: config)
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
    
    var text: String {
        get {
            var (_, rank) = config.lookup(str: combo.stringValue)
            if rank == nil {
                rank = RankValue()
            }
            return rank!.get(config: config)
        }
        set {
            let (_, rank) = config.lookup(str: newValue)
            if rank != nil {
                combo.stringValue = rank!.get(config: config)
            } else {
                combo.stringValue = newValue
            }
        }
    }
    
}

//
//  PickListView.swift
//  Notenik
//
//  Created by Herb Bowie on 5/11/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class PickListView: MacEditView {
    
    var pickListView: NSComboBox!
    var list = PickListDataSource()
    
    var view: NSView {
        return pickListView
    }
    
    var text: String {
        get {
            if pickListView.indexOfSelectedItem >= 0 {
                let item = list.item(at: pickListView.indexOfSelectedItem)
                if item == nil {
                    return pickListView.stringValue
                } else {
                    return item!
                }
            } else {
                return pickListView.stringValue
            }
        }
        set {
            var found = false
            var i = 0
            let newLower = newValue.lowercased()
            while !found && i < list.count {
                if newLower == list.item(at: i)!.lowercased() {
                    pickListView.selectItem(at: i)
                    found = true
                } else {
                    i += 1
                }
            }
            if !found {
                pickListView.stringValue = newValue
            }
        }
    }
    
    init() {
        buildView()
    }
    
    init(list: PickList) {
        self.list = PickListDataSource(list: list)
        buildView()
    }
    
    /// Build the ComboBox allowing the user to select a type of work.
    func buildView() {

        pickListView = NSComboBox(string: "")
        pickListView.usesDataSource = true
        pickListView.dataSource = list
        pickListView.delegate = list
        pickListView.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: pickListView)
    }

}

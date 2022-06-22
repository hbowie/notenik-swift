//
//  WorkTitleView.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class WorkTitleView: MacEditView {
    
    var workTitleField: NSComboBox!
    var workTitleDataSource = WorkTitleDataSource()
    
    var view: NSView {
        return workTitleField
    }
    
    var text: String {
        get {
            return workTitleField.stringValue
        }
        set {
            workTitleField.stringValue = newValue
        }
    }
    
    init(pickList: WorkTitlePickList) {
        buildView(pickList: pickList)
    }
    
    func buildView(pickList: WorkTitlePickList) {
        
        workTitleField = NSComboBox(string: "")
        workTitleField.usesDataSource = true
        workTitleDataSource = WorkTitleDataSource(workTitlePickList: pickList)
        workTitleField.dataSource = workTitleDataSource
        workTitleField.delegate = workTitleDataSource
        workTitleField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: workTitleField)
        
    }
    
}

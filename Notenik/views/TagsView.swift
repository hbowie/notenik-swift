//
//  TagsView.swift
//  Notenik
//
//  Created by Herb Bowie on 7/10/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class TagsView: MacEditView {
    
    var tagsField: NSTokenField!
    var tagsTokenDelegate: TagsTokenDelegate!
    
    var view: NSView {
        return tagsField
    }
    
    var text: String {
        get {
            return tagsField.stringValue
        }
        set {
            tagsField.stringValue = newValue
        }
    }
    
    init(pickList: TagsPickList) {
        buildView(pickList: pickList)
    }
    
    func buildView(pickList: TagsPickList) {
        tagsField = NSTokenField(string: "")
        AppPrefsCocoa.shared.setTextEditingFont(object: tagsField)
        tagsField.tokenizingCharacterSet = CharacterSet([",",";"])
        tagsTokenDelegate = TagsTokenDelegate(tagsPickList: pickList)
        tagsField.delegate = tagsTokenDelegate

    }
    
}

//
//  AuthorView.swift
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

class AuthorView: MacEditView {
    
    var authorField: NSComboBox!
    var authorDataSource: AuthorDataSource!
    
    var view: NSView {
        return authorField
    }
    
    var text: String {
        get {
            return authorField.stringValue
        }
        set {
            authorField.stringValue = newValue
        }
    }
    
    init(pickList: AuthorPickList) {
        buildView(pickList: pickList)
    }
    
    func buildView(pickList: AuthorPickList) {
        authorField = NSComboBox(string: "")
        authorField.usesDataSource = true
        authorDataSource = AuthorDataSource(authorPickList: pickList)
        authorField.dataSource = authorDataSource
        authorField.delegate = authorDataSource
        authorField.completes = true
        AppPrefsCocoa.shared.setTextEditingFont(object: authorField)
    }
    
}

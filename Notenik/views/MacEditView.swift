//
//  MacEditView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// A protocol for a class that can be used to allow a user to edit a text field
protocol MacEditView: ModView {
    
    var view: NSView { get }
    
    var text: String { get set }
    
}

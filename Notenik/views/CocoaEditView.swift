//
//  EditView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

/// A protocol for a class that can be used to allow a user to edit a text field
protocol CocoaEditView: ModView {
    
    var view: NSView { get }
    
    var text: String { get set }
    
}

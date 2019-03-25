//
//  ViewFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class ViewFactory {
    
    static func getEditView(def: FieldDefinition) -> EditView {
        return StringView()
    }
}

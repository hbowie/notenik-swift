//
//  ViewFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class ViewFactory {
    
    static func getEditView(collection: NoteCollection, def: FieldDefinition) -> CocoaEditView {
        if def.fieldType == .longText || def.fieldType == .code {
            return LongTextView()
        } else if def.fieldType == .status {
            return StatusView(config: collection.statusConfig)
        } else if def.fieldType == .date {
            return DateView()
        } else if def.fieldType == .label  || def.fieldType == .dateAdded {
            return LabelView()
        } else {
            return StringView()
        }
    }
}

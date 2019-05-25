//
//  ViewFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ViewFactory {
    
    static func getEditView(collection: NoteCollection, def: FieldDefinition) -> CocoaEditView {
        if def.fieldType == .body {
            return BodyView()
        } else if def.fieldType == .code {
            return CodeView()
        } else if def.fieldType == .longText {
            return LongTextView()
        } else if def.fieldType == .link {
            return LinkView()
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

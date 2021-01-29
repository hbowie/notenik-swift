//
//  ViewFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// A factory for making UI Views that can be used to edit the values of the
/// corresponding fields. 
class ViewFactory {
    
    static func getEditView(pickLists: ValuePickLists, def: FieldDefinition) -> MacEditView {
        if let pickList = def.pickList as? AuthorPickList {
            return AuthorView(pickList: pickList)
        } else if def.fieldType.typeString == NotenikConstants.bodyCommon {
            return BodyView()
        } else if def.fieldType.typeString == NotenikConstants.codeCommon {
            return CodeView()
        } else if def.fieldType.typeString == "longtext" {
            return LongTextView()
        } else if def.fieldType.typeString == NotenikConstants.linkCommon
                    || def.fieldType.typeString == NotenikConstants.workLinkCommon {
            return LinkView()
        } else if def.fieldType.typeString == NotenikConstants.statusCommon {
            return StatusView(config: pickLists.statusConfig)
        } else if def.fieldType.typeString == NotenikConstants.dateCommon {
            return DateView()
        } else if def.fieldType.typeString == NotenikConstants.tagsCommon {
            return TagsView(pickList: pickLists.tagsPickList)
        } else if def.fieldType.typeString == "label"
            || def.fieldType.typeString == "dateadded"
            || def.fieldType.typeString == "datemodified"
            || def.fieldType.typeString == "timestamp" {
            return LabelView()
        } else if def.fieldType.typeString == NotenikConstants.workTypeCommon {
            return WorkTypeView()
        } else if def.fieldType.typeString == NotenikConstants.workTitleCommon {
            return WorkTitleView(pickList: pickLists.workTitlePickList)
        } else if def.fieldType.typeString == "boolean" {
            return BooleanView()
        } else if def.pickList != nil {
            return PickListView(list: def.pickList!)
        } else {
            return StringView()
        }
    }
}

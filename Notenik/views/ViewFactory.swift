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

/// A factory for making UI Views that can be used to edit the values of the
/// corresponding fields. 
class ViewFactory {
    
    static func getEditView(pickLists: ValuePickLists, def: FieldDefinition) -> MacEditView {
        if def.fieldType.typeString == "author" {
            return AuthorView(pickList: pickLists.authorPickList)
        } else if def.fieldType.typeString == "body" {
            return BodyView()
        } else if def.fieldType.typeString == "code" {
            return CodeView()
        } else if def.fieldType.typeString == "longtext" {
            return LongTextView()
        } else if def.fieldType.typeString == "link" {
            return LinkView()
        } else if def.fieldType.typeString == "status" {
            return StatusView(config: pickLists.statusConfig)
        } else if def.fieldType.typeString == "date" {
            return DateView()
        } else if def.fieldType.typeString == "tags" {
            return TagsView(pickList: pickLists.tagsPickList)
        } else if def.fieldType.typeString == "label"
            || def.fieldType.typeString == "dateadded"
            || def.fieldType.typeString == "timestamp" {
            return LabelView()
        } else if def.fieldType.typeString == "worktype" {
            return WorkTypeView()
        } else if def.fieldType.typeString == "work" {
            return WorkTitleView(pickList: pickLists.workTitlePickList)
        } else {
            return StringView()
        }
    }
}

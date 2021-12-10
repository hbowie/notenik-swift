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
        }
        
        switch def.fieldType.typeString {
        case NotenikConstants.akaCommon:
            return AKAView()
        case NotenikConstants.attribCommon:
            return LongTextView()
        case NotenikConstants.backlinksCommon:
            return LabelView()
        case NotenikConstants.bodyCommon:
            return BodyView()
        case NotenikConstants.booleanType:
            return BooleanView()
        case NotenikConstants.codeCommon:
            return CodeView()
        case NotenikConstants.dateAddedCommon:
            return LabelView()
        case NotenikConstants.dateCommon:
            return DateView()
        case NotenikConstants.dateModifiedCommon:
            return LabelView()
        case NotenikConstants.imageNameCommon:
            return ImageNameView()
        case NotenikConstants.klassCommon:
            if let pickList = def.pickList as? KlassPickList {
                return KlassView(pickList: pickList)
            } else {
                let defaultList = KlassPickList()
                defaultList.setDefaults()
                return KlassView(pickList: defaultList)
            }
        case NotenikConstants.labelType:
            return LabelView()
        case NotenikConstants.levelCommon:
            return LevelView(config: pickLists.levelConfig)
        case NotenikConstants.linkCommon, NotenikConstants.workLinkCommon:
            return LinkView()
        case NotenikConstants.longTextType:
            return LongTextView()
        case NotenikConstants.lookupType:
            return LookupView(def: def)
        case NotenikConstants.minutesToReadCommon:
            return LabelView()
        case NotenikConstants.shortIdCommon:
            return ShortIdView()
        case NotenikConstants.statusCommon:
            return StatusView(config: pickLists.statusConfig)
        case NotenikConstants.tagsCommon:
            return TagsView(pickList: pickLists.tagsPickList)
        case NotenikConstants.timestampCommon:
            return LabelView()
        case NotenikConstants.wikilinksCommon:
            return LabelView()
        case NotenikConstants.workTitleCommon:
            return WorkTitleView(pickList: pickLists.workTitlePickList)
        case NotenikConstants.workTypeCommon:
            return WorkTypeView()
        default:
            if def.pickList != nil {
                return PickListView(list: def.pickList!)
            } else {
                return StringView()
            }
        }
    }
}

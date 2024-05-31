//
//  ViewFactory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/8/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// A factory for making UI Views that can be used to edit the values of the
/// corresponding fields. 
class ViewFactory {
    
    static func getEditView(collection: NoteCollection,
                            pickLists: ValuePickLists,
                            def: FieldDefinition,
                            auxLongText: Bool) -> MacEditView {
        
        switch def.fieldType.typeString {
        case NotenikConstants.addressCommon:
            if auxLongText {
                let addressView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                              typeString: def.fieldType.typeString)
                return addressView
            } else {
                return LinkView(def: def)
            }
        case NotenikConstants.akaCommon:
            return AKAView()
        case NotenikConstants.attribCommon:
            if auxLongText {
                let longView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                           typeString: def.fieldType.typeString)
                return longView
            } else {
                return LongTextView()
            }
        case NotenikConstants.authorCommon:
            if let pickList = def.pickList as? AuthorPickList {
                return AuthorView(pickList: pickList)
            } else {
                return StringView()
            }
        case NotenikConstants.backlinksCommon:
            return LabelView()
        case NotenikConstants.bodyCommon:
            return BodyView(minBodyEditViewHeight: collection.minBodyEditViewHeight)
        case NotenikConstants.booleanType:
            return BooleanView()
        case NotenikConstants.codeCommon:
            if auxLongText {
                let codeView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                           typeString: def.fieldType.typeString)
                return codeView
            } else {
                return CodeView()
            }
        case NotenikConstants.comboType:
            return ComboView(def: def)
        case NotenikConstants.dateAddedCommon:
            return LabelView()
        case NotenikConstants.dateCommon:
            return DateView()
        case NotenikConstants.dateModifiedCommon:
            return LabelView()
        case NotenikConstants.directionsCommon:
            return DirectionsView()
        case NotenikConstants.durationCommon:
            return DurationView()
        case NotenikConstants.folderCommon:
            return ComboView(def: def)
        case NotenikConstants.imageNameCommon:
            return ImageNameView()
        case NotenikConstants.includeChildrenCommon:
            return IncludeChildrenView()
        case NotenikConstants.indexCommon:
            if auxLongText {
                let indexView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                            typeString: def.fieldType.typeString)
                return indexView
            } else {
                return LongTextView()
            }
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
            if auxLongText {
                let linkView = AuxTextView(properLabel: def.fieldLabel.properForm, typeString: def.fieldType.typeString)
                return linkView
            } else {
                return LinkView(def: def)
            }
        case NotenikConstants.longTextType:
            if auxLongText {
                let longView = AuxTextView(properLabel: def.fieldLabel.properForm, typeString: def.fieldType.typeString)
                return longView
            } else {
                return LongTextView()
            }
        case NotenikConstants.lookupType:
            return LookupView(def: def)
        case NotenikConstants.minutesToReadCommon:
            return LabelView()
        case NotenikConstants.pageStyleCommon:
            if auxLongText {
                let psView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                         typeString: def.fieldType.typeString)
                return psView
            } else {
                return PageStyleView()
            }
        case NotenikConstants.personCommon:
            return PersonView()
        case NotenikConstants.rankCommon:
            return RankView(config: collection.rankConfig)
        case NotenikConstants.shortIdCommon:
            return ShortIdView()
        case NotenikConstants.statusCommon:
            return StatusView(config: pickLists.statusConfig)
        case NotenikConstants.tagsCommon:
            return TagsView(pickList: pickLists.tagsPickList)
        case NotenikConstants.teaserCommon:
            if auxLongText {
                let teaserView = AuxTextView(properLabel: def.fieldLabel.properForm,
                                             typeString: def.fieldType.typeString)
                return teaserView
            } else {
                return TeaserView()
            }
        case NotenikConstants.textFormatCommon:
            return TextFormatView()
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

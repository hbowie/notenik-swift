//
//  Field.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Indicates how this field is to be handled.
enum FieldType: String {
    case defaultType    = "default"
    case string         = "string"
    case title          = "title"
    case body           = "body"
    case longText       = "longtext"
    case tags           = "tags"
    case link           = "link"
    case label          = "label"
    case author         = "author"
    case date           = "date"
    case rating         = "rating"
    case status         = "status"
    case seq            = "seq"
    case index          = "index"
    case recurs         = "recurs"
    case code           = "code"
    case dateAdded      = "dateadded"
    case work           = "work"
    case workType       = "worktype"
    case artist         = "artist"
    case pickFromList   = "picklist"
}


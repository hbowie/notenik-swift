//
//  MergeActionModifier.swift
//  Notenik
//
//  Created by Herb Bowie on 5/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

enum MergeActionModifier: String {
    case blank = ""
    case url   = "url"
    case file  = "file"
    case dir   = "dir"
    case html1 = "html1"
    case html2 = "html2"
    case html3 = "html3"
    case notenikPlus = "notenik+"
    case text  = "text"
    case xml   = "xml"
    case xls   = "xls"
    case ascending  = "ascending"
    case descending = "descending"
    case operater   = "operator"
    case notEqual   = "not equal to"
    case greaterOrEqual = "greater than or equal to"
}

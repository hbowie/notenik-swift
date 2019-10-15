//
//  TextileLineType.swift
//  Notenik
//
//  Created by Herb Bowie on 10/3/19.
//
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An indicator of the type of Textile line. 
enum TextileLineType {
    case blank
    case ordinary
    case unordered
    case ordered
    case definitionTerm
    case definitionDef
    case html
}

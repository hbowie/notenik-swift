//
//  MkdownLineType.swift
//  Notenik
//
//  Created by Herb Bowie on 3/1/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

enum MkdownLineType {
    case blank
    case code
    case h1Underlines
    case h2Underlines
    case heading
    case horizontalRule
    case linkDef
    case linkDefExt
    case orderedItem
    case ordinaryText
    case unorderedItem
    
    var isListItem: Bool {
        return self == .orderedItem || self == .unorderedItem
    }
    
    var hasText: Bool {
        return self != .blank && self != .h1Underlines && self != .h2Underlines && self != .horizontalRule && self != .linkDefExt && self != .linkDefExt
    }
}



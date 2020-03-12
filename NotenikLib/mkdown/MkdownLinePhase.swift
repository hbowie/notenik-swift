//
//  MkdownLinePhase.swift
//  Notenik
//
//  Created by Herb Bowie on 3/4/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

/// The phases of evaluation for a line of Markdown, proceeding from left to right. 
enum MkdownLinePhase {
    case leadingPunctuation
    case text
}

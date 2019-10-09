//
//  TextileOpeningClosing.swift
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

/// An indicator of where some special sequence of characters falls
/// in relationship to other sequences of the same kind. 
enum TextileOpeningClosing {
    case opening
    case closing
    case singular
}

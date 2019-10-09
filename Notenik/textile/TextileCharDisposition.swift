//
//  TextileCharDisposition.swift
//  Notenik
//
//  Created by Herb Bowie on 10/4/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Indicates the disposition of a textile character being scanned within the block
/// (beyond the signature).)
enum TextileCharDisposition {
    case text
    case pending
    case special
    case skip
    case href
}

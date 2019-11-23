//
//  NoteDisplayFormat.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation


/// Allowable display formats for Markedup
///
/// - html:     Format as HTML
/// - markdown: Format as Markdown
enum MarkedupFormat: Int {
    case htmlFragment = 0
    case htmlDoc      = 1
    case markdown     = 2
    case netscapeBookmarks = 3
}

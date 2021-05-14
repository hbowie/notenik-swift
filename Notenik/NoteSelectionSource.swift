//
//  NoteSelectionSource.swift
//  Notenik
//
//  Created by Herb Bowie on 2/12/19.
//  Copyright © 2019 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

enum NoteSelectionSource {
    case nav        // User navigated to this note
    case list       // Selected from the list view
    case tree       // Selected from the tags/outline view
    case action     // Selected as the result of some action
}

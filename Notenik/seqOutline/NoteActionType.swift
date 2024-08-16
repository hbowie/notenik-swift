//
//  NoteActionType.swift
//  Notenik
//
//  Created by Herb Bowie on 8/13/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum NoteActionType: String {
    case showInFinder   = "Show in Finder"
    case launchLink     = "Launch Link"
    case share          = "Share..."
    case copyNotenikURL = "Copy Notenik URL"
    case copyTitle      = "Copy Title"
    case copyTimestamp  = "Copy Timestamp"
    case bulkEdit       = "Bulk Edit..."
    case newWithOptions = "New with Options..."
    case duplicate      = "Duplicate"
    case deleteRange    = "Delete Range..."
    case newChild       = "New Child"
    case modifySeqRange = "Modify Seq..."
}

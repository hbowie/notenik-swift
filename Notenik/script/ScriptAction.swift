//
//  ScriptAction.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

enum ScriptAction: String {
    case blank    = ""
    case add      = "add"
    case clear    = "clear"
    case epubin   = "epubin"
    case epubout  = "epubout"
    case generate = "generate"
    case open     = "open"
    case set      = "set"
    case webroot  = "webroot"
}

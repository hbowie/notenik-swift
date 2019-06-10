//
//  TemplateCommands.swift
//  Notenik
//
//  Created by Herb Bowie on 6/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

enum TemplateCommand: String {
    case comment     = "*"
    case debug       = "debug"
    case definegroup = "definegroup"
    case delims      = "delims"
    case elseCmd     = "else"
    case endif       = "endif"
    case epub        = "epub"
    case ifCmd       = "if"
    case ifchange    = "ifchange"
    case ifendgroup  = "ifendgroup"
    case ifendlist   = "ifendlist"
    case ifnewgroup  = "ifnewgroup"
    case ifnewlist   = "ifnewlist"
    case include     = "include"
    case loop        = "loop"
    case nextrec     = "nextrec"
    case outer       = "outer"
    case outerloop   = "outerloop"
    case output      = "output"
    case set         = "set"
}

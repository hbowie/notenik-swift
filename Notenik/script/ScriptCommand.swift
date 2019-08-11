//
//  ScriptCommand.swift
//  Notenik
//
//  Created by Herb Bowie on 7/24/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One command to be executed by the Scripting Engine.
class ScriptCommand {
    var module:   ScriptModule = .blank
    var action:   ScriptAction = .blank
    var modifier  = ""
    var object    = ""
    var value     = ""
    var valueWithPathResolved = ""
}

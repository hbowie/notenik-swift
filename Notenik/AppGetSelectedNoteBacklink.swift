//
//  AppGetSelectedNoteBacklink.swift
//  Notenik
//
//  Created by Herb Bowie on 3/23/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@objc class AppGetSelectedNoteBacklink: NSScriptCommand {
    
    override func performDefaultImplementation() -> Any? {
        return CollectionJuggler.shared.getLastSelectedNoteCustomURL()
    }

}

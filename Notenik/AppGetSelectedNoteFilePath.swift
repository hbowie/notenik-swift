//
//  AppGetSelectedNoteFilePath.swift
//  Notenik
//
//  Created by Herb Bowie on 3/29/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@objc class AppGetSelectedNoteFilePath: NSScriptCommand {
    
    override func performDefaultImplementation() -> Any? {
        let filepath = CollectionJuggler.shared.getLastSelectedNoteFilePath()
        return filepath
    }


}

//
//  CocoaFontUsage.swift
//  Notenik
//
//  Created by Herb Bowie on 6/21/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Identifies how a Cocoa font is to be used within the Notenik Edit tab. 
public enum CocoaFontUsage: String {
    case labels = "labels"
    case text   = "text"
    case code   = "code"
}

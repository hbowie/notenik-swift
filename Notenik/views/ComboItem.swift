//
//  ComboItem.swift
//  Notenik
//
//  Created by Herb Bowie on 12/2/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// An item made available to a combo box via the ComboData class. 
class ComboItem: Comparable, Equatable, CustomStringConvertible, NSCopying {

    var str = ""
    var strLower = ""
    
    var description: String {
        return str
    }
    
    init(_ str: String) {
        self.str = str
        strLower = str.lowercased()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return ComboItem(str)
    }
    
    static func < (lhs: ComboItem, rhs: ComboItem) -> Bool {
        if lhs.strLower < rhs.strLower {
            return true
        } else if lhs.strLower > rhs.strLower {
            return false
        } else if lhs.str < rhs.str {
            return true
        } else {
            return false
        }
    }
    
    static func == (lhs: ComboItem, rhs: ComboItem) -> Bool {
        return (lhs.strLower == rhs.strLower && lhs.str == rhs.str)
    }
}

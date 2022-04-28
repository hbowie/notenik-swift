//
//  QuickActionFolder.swift
//  Notenik
//
//  Created by Herb Bowie on 5/11/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikLib

class QuickActionFolder: CustomStringConvertible, NSCopying, Comparable {
    
    var shortcut = ""
    var link: NotenikLink!
    
    init() {
        shortcut = ""
        link = NotenikLink()
    }
    
    init(shortcut: String, link: NotenikLink) {
        self.shortcut = shortcut.lowercased()
        self.link = link
    }
    
    var description: String {
        return shortcut
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = QuickActionFolder(shortcut: shortcut, link: link)
        return copy
    }
    
    var sortKey: String {
        return shortcut + " - " + link.path
    }
    
    static func < (lhs: QuickActionFolder, rhs: QuickActionFolder) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }
    
    static func == (lhs: QuickActionFolder, rhs: QuickActionFolder) -> Bool {
        return lhs.sortKey == rhs.sortKey
    }
    
}

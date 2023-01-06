//
//  NavigatorFolder.swift
//  Notenik
//
//  Created by Herb Bowie on 1/12/21.
//
//  Copyright © 2021 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikLib

class NavigatorFolder: CustomStringConvertible, NSCopying, Comparable {

    var folder = ""
    var link: NotenikLink!
    
    init(link: NotenikLink, handle: String) {
        self.folder = handle
        self.link = link
    }
    
    var description: String {
        return folder
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = NavigatorFolder(link: self.link, handle: folder)
        return copy
    }
    
    var sortKey: String {
        return folder + link.path
    }
    
    static func < (lhs: NavigatorFolder, rhs: NavigatorFolder) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }
    
    static func == (lhs: NavigatorFolder, rhs: NavigatorFolder) -> Bool {
        return lhs.sortKey == rhs.sortKey
    }

}

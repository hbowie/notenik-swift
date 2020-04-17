//
//  TagsTokenDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 7/10/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// Implement delegate functions for the Tags field on the Edit screen.
class TagsTokenDelegate: NSObject, NSTokenFieldDelegate, NSTokenFieldCellDelegate {
    
    var tagsPickList = TagsPickList()
    var selIx = 0
    
    override init() {
        super.init()
    }
    
    convenience init(tagsPickList: TagsPickList) {
        self.init()
        self.tagsPickList = tagsPickList
    }
    
    func tokenField(_ tokenField: NSTokenField,
                             completionsForSubstring substring: String,
                             indexOfToken tokenIndex: Int,
                             indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return completionsForSubstring(substring)
    }
    
    func tokenFieldCell(_ tokenFieldCell: NSTokenFieldCell,
                        completionsForSubstring substring: String,
                        indexOfToken tokenIndex: Int,
                        indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [Any] {
        return completionsForSubstring(substring)
    }
    
    func completionsForSubstring(_ substring: String) -> [Any] {
        var possibilities: [String] = []
        var i = 0
        var looking = true
        while looking && i < tagsPickList.values.count {
            if tagsPickList.values[i].value.hasPrefix(substring) {
                possibilities.append(tagsPickList.values[i].value)
            } else if tagsPickList.values[i].value > substring {
                looking = false
            }
            i += 1
        }
        
        if possibilities.count > 0 {
            selIx = 0
        } else {
            selIx = -1
        }
        return possibilities
    }
    
}

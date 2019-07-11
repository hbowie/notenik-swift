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

class TagsTokenDelegate: NSObject, NSTokenFieldDelegate {
    
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
        var possibilities: [String] = []
        let allTags = tagsPickList.values
        var i = 0
        var looking = true
        while looking {
            if allTags[i].hasPrefix(substring) {
                possibilities.append(allTags[i])
            } else if allTags[i] > substring {
                looking = false
            }
            i += 1
        }
        if possibilities.count > 0 {
            selIx = 0
            
        }
        return possibilities
    }
    
}

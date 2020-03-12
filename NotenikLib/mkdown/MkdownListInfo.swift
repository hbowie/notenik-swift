//
//  MkdownListInfo.swift
//  Notenik
//
//  Created by Herb Bowie on 3/6/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

class MkdownListInfo {
    
    var type: MkdownListType = .na
    var withParagraphs = false
    var level = 0
    var number = 0
    
    func setTypeFrom(lineType: MkdownLineType) {
        switch lineType {
        case .orderedItem:
            type = .ordered
        case .unorderedItem:
            type = .unordered
        default:
            break
        }
    }
    
    func continues(existingList: MkdownListInfo) -> Bool {
        return (self.type  == existingList.type
             && self.level == existingList.level
             && self.number != 1)
    }
    
}

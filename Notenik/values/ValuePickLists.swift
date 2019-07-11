//
//  ValuePickLists.swift
//  Notenik
//
//  Created by Herb Bowie on 7/11/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class ValuePickLists {
    
    var statusConfig = StatusValueConfig()
    var tagsPickList = TagsPickList()
    
    /// Register the relevant values from another Note. 
    func registerNote(note: Note) {
        if note.hasTags() {
            tagsPickList.registerTags(note.tags)
        }
    }
}

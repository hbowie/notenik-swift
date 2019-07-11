//
//  TagsPickList.swift
//  Notenik
//
//  Created by Herb Bowie on 7/11/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A list of Tags that can be picked from. 
class TagsPickList: PickList {
    
    func registerTags(_ tags: TagsValue) {
        for tag in tags.tags {
            let tagStr = String(describing: tag)
            registerValue(tagStr)
        } // end for each tag in the tags value
    } // end register tags
    
}

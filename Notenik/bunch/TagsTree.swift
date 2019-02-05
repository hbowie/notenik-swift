//
//  TagsTree.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

class TagsTree {
    
    let root = TagsNode()
    
    func add(note: Note) {
        if note.hasTags() {
            let tags = note.tags
            var i = 0
            while i < tags.tags.count {
                let tag = tags.tags[i]
                var node = root
                var j = 0
                while j < tag.levels.count {
                    let level = tag.levels[j]
                    let nextNode = node.addChild(tagLevel: level)
                    node = nextNode
                    j += 1
                }
                _ = node.addChild(note: note)
                i += 1
            }
        } else {
            _ = root.addChild(note: note)
        }
    }
    
}

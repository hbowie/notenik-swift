//
//  TagsNodeIterator.swift
//  Notenik
//
//  Created by Herb Bowie on 7/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class to iterate over a collection of notes in sequence by
/// tags. Note that the same note may appear more than once
/// (if it has multiple tags). Also note that the root node
/// will not be returned. 
class TagsNodeIterator: IteratorProtocol {
    
    var noteIO: NotenikIO?
    var positions: [Int] = []
    var tagsNode: TagsNode? = nil
    var depth = 0
    
    /// Initialize with the NotenikIO instance.
    init(noteIO: NotenikIO) {
        self.noteIO = noteIO
        tagsNode = noteIO.getTagsNodeRoot()
    }
    
    /// Return the next TagsNode, or nil at the end.
    func next() -> TagsNode? {
        var nextNode: TagsNode? = nil
        if tagsNode!.children.count > 0 {
            setPosition(depth: depth, position: 0)
            nextNode = tagsNode!.children[0]
            depth += 1
        } else {
            depth -= 1
            var checkNode = tagsNode
            while depth >= 0 && nextNode == nil {
                let parent = checkNode!.parent
                let siblingPosition = positions[depth] + 1
                if siblingPosition < parent!.children.count {
                    setPosition(depth: depth, position: siblingPosition)
                    nextNode = parent!.children[siblingPosition]
                    depth += 1
                } else {
                    depth -= 1
                    checkNode = parent
                }
            }
        }
        tagsNode = nextNode
        return nextNode
    }
    
    /// Set the position within the list of children at the given level.
    func setPosition(depth: Int, position: Int) {
        if depth >= positions.count {
            positions.append(position)
        } else {
            positions[depth] = position
        }
    }
}

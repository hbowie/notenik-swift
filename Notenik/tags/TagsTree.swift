//
//  TagsTree.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A tree structure listing notes in a collection by their tags.
class TagsTree {
    
    let root = TagsNode()
    
    /// Add a note to the Tags Tree, with one leaf for each Tag that the note possesses
    func add(note: Note) {
        if note.hasTags() {
            let tags = note.tags
            var i = 0
            
            // Process each tag separately
            while i < tags.tags.count {
                let tag = tags.tags[i]
                var node = root
                var j = 0
                while j < tag.levels.count {
                    // Now let's work our way up through the tag's levels,
                    // adding (or locating) one tag level at a time, working
                    // our way deeper into the tree structure as we go.
                    let level = tag.levels[j]
                    let nextNode = node.addChild(tagLevel: level)
                    node = nextNode
                    j += 1
                }
                
                // Now that we've worked our way through the tags,
                // Add the note itself to the tree.
                _ = node.addChild(note: note)
                
                // And on to the next tag for this note
                i += 1
            }
        } else {
            // If no tags for this note, then just add the note to the root node. 
            _ = root.addChild(note: note)
        }
    }
    
    /// Delete a note from the tree, wherever it appears
    func delete(note: Note) {
        deleteNoteInChildren (note: note, node: root)
    }
    
    /// Delete child nodes where this Note is found
    func deleteNoteInChildren(note: Note, node: TagsNode) {
        var i = 0
        while i < node.countChildren {
            let child = node.getChild(at: i)
            if child!.type == .note {
                if child!.note!.noteID == note.noteID {
                    node.remove(at: i)
                } else {
                    i += 1
                }
            } else {
                deleteNoteInChildren(note: note, node: child!)
                i += 1
            }
        }
    }
    
}

//
//  TagsNode.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A single node in the Tags Tree.
class TagsNode: Comparable, CustomStringConvertible {
    
    static let thisLessThanThat = -1
    static let thisGreaterThanThat = 1
    static let thisEqualsThat = 0
    
    static func < (lhs: TagsNode, rhs: TagsNode) -> Bool {
        return lhs.compareTo(node2: rhs) < 0
    }
    
    static func == (lhs: TagsNode, rhs: TagsNode) -> Bool {
        return lhs.compareTo(node2: rhs) == 0
    }
    
    private(set) weak var parent:   TagsNode?
    private(set)      var children: [TagsNode] = []
                      var type:     TagsNodeType = .root
                      var tag:      String?
                      var note:     Note?
    
    init() {
        
    }
    
    convenience init(tag: String) {
        self.init()
        type = .tag
        self.tag = tag
    }
    
    convenience init(note: Note) {
        self.init()
        type = .note
        self.note = note
    }
    
    var description: String {
        switch type {
        case .root:
            return "root"
        case .tag:
            return tag!
        case .note:
            return note!.title.value
        }
    }
    
    /// Compare this Tags Node to another one and determine which is greater.
    func compareTo(node2: TagsNode) -> Int {
        if self.type.rawValue < node2.type.rawValue {
            return TagsNode.thisLessThanThat
        } else if self.type.rawValue > node2.type.rawValue {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .tag && self.tag! < node2.tag! {
            return TagsNode.thisLessThanThat
        } else if self.type == .tag && self.tag! > node2.tag! {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .note && self.note! < node2.note! {
            return TagsNode.thisLessThanThat
        } else if self.type == .note && self.note! > node2.note! {
            return TagsNode.thisGreaterThanThat
        } else if self.type == .note && self.note!.noteID < node2.note!.noteID {
            return TagsNode.thisLessThanThat
        } else if self.type == .note && self.note!.noteID > node2.note!.noteID {
            return TagsNode.thisGreaterThanThat
        } else {
            return TagsNode.thisEqualsThat
        }
    }
    
    func addChild(tagLevel: String) -> TagsNode {
        let tagNode = TagsNode(tag: tagLevel)
        return addChild(node: tagNode)
    }
    
    func addChild(note: Note) -> TagsNode {
        let noteNode = TagsNode(note: note)
        return addChild(node: noteNode)
    }
    
    /// Either add the supplied node to this node at the proper insertion point,
    /// or determine that a node with an identical key already exists.
    ///
    /// - Parameter node: The node to be added, if it's not already there.
    /// - Returns: The node that was added, or the equal one that already existed. 
    func addChild(node: TagsNode) -> TagsNode {
        
        // Use binary search to look for a match or the
        // first item greater than the desired key.
        var index = 0
        var bottom = 0
        var top = children.count - 1
        var done = false
        while !done {
            if bottom > top {
                done = true
                index = bottom
            } else if top == bottom || top == (bottom + 1) {
                done = true
                if node > children[top] {
                    index = top + 1
                } else if node == children[top] {
                    return children[top]
                } else if node == children[bottom] {
                    return children[bottom]
                } else if node > children[bottom] {
                    index = top
                } else {
                    index = bottom
                }
            } else {
                let middle = bottom + ((top - bottom) / 2)
                if node == children[middle] {
                    return children[middle]
                } else if node > children[middle] {
                    bottom = middle + 1
                } else {
                    top = middle
                }
            }
        }
        
        if index >= children.count {
            node.parent = self
            children.append(node)
            return node
        } else if index < 0 {
            node.parent = self
            children.insert(node, at: 0)
            return node
        } else if node < children[index] {
            node.parent = self
            children.insert(node, at: index)
            return node
        } else {
            return children[index]
        }
    }
    
    /// Return the child at the specified index, or nil if bad index
    func getChild(at index: Int) -> TagsNode? {
        if index < 0 || index >= children.count {
            return nil
        } else {
            return children[index]
        }
    }
    
    /// Remove the child at the specified index.
    func remove(at index: Int) {
        if index >= 0 && index < children.count {
            children.remove(at: index)
        }
    }
    
    /// Return the number of children for which this node is a parent
    var countChildren: Int {
        return children.count
    }
}

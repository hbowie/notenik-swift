//
//  TagsNode.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

class TagsNode: Comparable {
    
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
    
    func addChild(node: TagsNode) -> TagsNode {
        var i = 0
        while i < children.count && node > children[i] {
            i += 1
        }
        if i >= children.count {
            node.parent = self
            children.append(node)
            return node
        } else if node < children[i] {
            node.parent = self
            children.insert(node, at: i)
            return node
        } else {
            return children[i]
        }
    }
}

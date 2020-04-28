//
//  CollectorIterator.swift
//  Notenik
//
//  Created by Herb Bowie on 4/22/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Foundation

class KnownFilesTreeIterator: IteratorProtocol {
    
    typealias Element = KnownFileNode
    
    var tree: KnownFiles
    var positions: [Int] = []
    var collectorNode: KnownFileNode? = nil
    var depth = 0
    
    /// Initialize with a Collector Tree.
    init(tree: KnownFiles) {
        self.tree = tree
        collectorNode = self.tree.root
    }
    
    /// Return the next CollectorNode, or nil at the end.
    public func next() -> KnownFileNode? {
        var nextNode: KnownFileNode? = nil
        if collectorNode!.children.count > 0 {
            setPosition(depth: depth, position: 0)
            nextNode = collectorNode!.children[0]
            depth += 1
        } else {
            depth -= 1
            var checkNode = collectorNode
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
        collectorNode = nextNode
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

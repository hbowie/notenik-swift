//
//  CollectorNode.swift
//  Notenik
//
//  Created by Herb Bowie on 4/21/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class CollectorNode: Comparable, CustomStringConvertible {
    
    static let thisLessThanThat = -1
    static let thisGreaterThanThat = 1
    static let thisEqualsThat = 0
    
    private(set) weak var parent:   CollectorNode?
    private(set)      var children: [CollectorNode] = []
    
    var type:     CollectorNodeType = .root
    var url:      URL?
    var base    = ""
    var path:     [String] = []
    var folder  = ""
    
    static func < (lhs: CollectorNode, rhs: CollectorNode) -> Bool {
        return lhs.compareTo(node2: rhs) == CollectorNode.thisLessThanThat
    }
    
    var description: String {
        if type == .root {
            return "root"
        } else if folder == "" {
            return base
        } else {
            return folder
        }
    }
    
    static func == (lhs: CollectorNode, rhs: CollectorNode) -> Bool {
        return lhs.compareTo(node2: rhs) == CollectorNode.thisEqualsThat
    }
    
    init() {
        
    }
    
    convenience init(_ url: URL, collection: Bool = false) {
        self.init()
        self.url = url
        if collection {
            type = .collection
        } else {
            type = .folder
        }
    }
    
    /// Compare this Node to another one and determine which is greater.
    func compareTo(node2: CollectorNode) -> Int {
        
        // Compare node types.
        if self.type.rawValue < node2.type.rawValue {
            return CollectorNode.thisLessThanThat
        } else if self.type.rawValue > node2.type.rawValue {
            return CollectorNode.thisGreaterThanThat
        }
        
        let baseLower1 = self.base.lowercased()
        let baseLower2 = node2.base.lowercased()
        if baseLower1 < baseLower2 {
            return CollectorNode.thisLessThanThat
        } else if baseLower1 > baseLower2 {
            return CollectorNode.thisGreaterThanThat
        } else if self.base < node2.base {
            return CollectorNode.thisLessThanThat
        } else if self.base > node2.base {
            return CollectorNode.thisGreaterThanThat
        }
            
        var i = 0
        while i < self.path.count && i < node2.path.count {
            let pathLower1 = self.path[i].lowercased()
            let pathLower2 = node2.path[i]
            if pathLower1 < pathLower2 {
                return CollectorNode.thisLessThanThat
            } else if pathLower1 > pathLower2 {
                return CollectorNode.thisGreaterThanThat
            } else if self.path[i] < node2.path[i] {
                return CollectorNode.thisLessThanThat
            } else if self.path[i] > node2.path[i] {
                return CollectorNode.thisGreaterThanThat
            }
            i += 1
        }
        
        if self.path.count < node2.path.count {
            return CollectorNode.thisLessThanThat
        } else if self.path.count > node2.path.count {
            return CollectorNode.thisGreaterThanThat
        }

        let folderLower1 = self.folder.lowercased()
        let folderLower2 = node2.folder.lowercased()
        if folderLower1 < folderLower2 {
            return CollectorNode.thisLessThanThat
        } else if folderLower1 > folderLower2 {
            return CollectorNode.thisGreaterThanThat
        } else if self.folder < node2.folder {
            return CollectorNode.thisLessThanThat
        } else if self.folder > node2.folder {
            return CollectorNode.thisGreaterThanThat
        }
        
        return CollectorNode.thisEqualsThat
    }
    
    /// Populate the path array with the specified folder range. 
    func populatePath(folders: [String], start: Int, number: Int) {
        path = []
        for index in start ..< start + number {
            path.append(folders[index])
        }
    }
    
    /// Add the passed child node, unless one with the same keys already exists. Pass back
    /// the one added or the equal found.
    func addChild(_ newChild: CollectorNode) -> CollectorNode {
        var i = 0
        var childNode: CollectorNode?
        while i < children.count {
            childNode = children[i]
            if newChild == childNode! {
                return childNode!
            } else if newChild < childNode! {
                addChild(newChild, at: i)
                return newChild
            } else {
                i += 1
            }
        }
        addChild(newChild, at: i)
        return newChild
    }
    
    /// Add a child to this node. 
    func addChild(_ child: CollectorNode, at: Int) {
        child.parent = self
        if at >= children.count {
            children.append(child)
        } else {
            children.insert(child, at: at)
        }
    }
    
    /// Return the child at the specified index, or nil if bad index
    func getChild(at index: Int) -> CollectorNode? {
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
    
    /// Display values for debugging purposes. 
    func display() {
        print(" ")
        print("  Collector Node")
        if url != nil {
            print("    URL = \(url!.absoluteString)")
        }
        print("    Type = \(type)")
        print("    Base = \(base)")
        for segment in path {
            print("    Path = \(segment)")
        }
        print("    Folder = \(folder)")
        print("    # of Children = \(children.count)")
    }
    
}

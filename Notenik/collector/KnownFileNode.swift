//
//  KnownFileNode.swift
//  Notenik
//
//  Created by Herb Bowie on 4/21/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

class KnownFileNode: Comparable, CustomStringConvertible {
    
    let thisLessThanThat = -1
    let thisGreaterThanThat = 1
    let thisEqualsThat = 0
    
    private(set) weak var parent:   KnownFileNode?
    private(set)      var children: [KnownFileNode] = []
    
                      var tree:     KnownFiles
    
    var type:     KnownFileNodeType = .root
    var _url:      URL?
    var base    = KnownFileBase()
    var path:     [String] = []
    var folder  = ""
    
    static func < (lhs: KnownFileNode, rhs: KnownFileNode) -> Bool {
        return lhs.compareTo(node2: rhs) == lhs.thisLessThanThat
    }
    
    static func == (lhs: KnownFileNode, rhs: KnownFileNode) -> Bool {
        return lhs.compareTo(node2: rhs) == lhs.thisEqualsThat
    }
    
    var description: String {
        if type == .root {
            return "tree root"
        } else if folder == "" {
            return base.name
        } else {
            return folder
        }
    }
    
    var url: URL {
        set {
            _url = newValue
        }
        get {
            if _url != nil {
                return _url!
            }
            var fileURL = base.url
            for component in path {
                fileURL.appendPathComponent(component, isDirectory: true)
            }
            if folder.count > 0 {
                fileURL.appendPathComponent(folder, isDirectory: true)
            }
            return fileURL
        }
    }
    
    init(tree: KnownFiles) {
        self.tree = tree
    }
    
    convenience init(tree: KnownFiles, url: URL, collection: Bool = false) {
        self.init(tree: tree)
        self.url = url
        if collection {
            type = .collection
        } else {
            type = .folder
        }
    }
    
    /// Compare this Node to another one and determine which is greater.
    func compareTo(node2: KnownFileNode) -> Int {
        
        // Compare node types.
        var result = compareType(node2: node2)
        guard result == thisEqualsThat else { return result }
        
        result = compareBase(node2: node2)
        guard result == thisEqualsThat else { return result }
            
        result = comparePath(node2: node2)
        guard result == thisEqualsThat else { return result }

        return compareFolder(node2: node2)
    }
    
    func compareType(node2: KnownFileNode) -> Int {
        if self.type == node2.type {
            return thisEqualsThat
        } else if self.type.rawValue < node2.type.rawValue {
            return thisLessThanThat
        } else if self.type.rawValue > node2.type.rawValue {
            return thisGreaterThanThat
        }
        return thisEqualsThat
    }
    
    func compareBase(node2: KnownFileNode) -> Int {
        if self.base.name == node2.base.name {
            return thisEqualsThat
        }
        let baseLower1 = self.base.name.lowercased()
        let baseLower2 = node2.base.name.lowercased()
        if baseLower1 < baseLower2 {
            return thisLessThanThat
        } else if baseLower1 > baseLower2 {
            return thisGreaterThanThat
        } else if self.base.name < node2.base.name {
            return thisLessThanThat
        } else if self.base.name > node2.base.name {
            return thisGreaterThanThat
        }
        return thisEqualsThat
    }
    
    func comparePath(node2: KnownFileNode) -> Int {
        var i = 0
        while i < self.path.count && i < node2.path.count {
            if self.path[i] == node2.path[i] {
                i += 1
                continue
            }
            let pathLower1 = self.path[i].lowercased()
            let pathLower2 = node2.path[i].lowercased()
            if pathLower1 < pathLower2 {
                return thisLessThanThat
            } else if pathLower1 > pathLower2 {
                return thisGreaterThanThat
            } else if self.path[i] < node2.path[i] {
                return thisLessThanThat
            } else if self.path[i] > node2.path[i] {
                return thisGreaterThanThat
            }
            i += 1
        }
        
        if self.path.count < node2.path.count {
            return thisLessThanThat
        } else if self.path.count > node2.path.count {
            return thisGreaterThanThat
        }
        return thisEqualsThat
    }
    
    func compareFolder(node2: KnownFileNode) -> Int {
        if self.folder == node2.folder {
            return thisEqualsThat
        }
        let folderLower1 = self.folder.lowercased()
        let folderLower2 = node2.folder.lowercased()
        if folderLower1 < folderLower2 {
            return thisLessThanThat
        } else if folderLower1 > folderLower2 {
            return thisGreaterThanThat
        } else if self.folder < node2.folder {
            return thisLessThanThat
        } else if self.folder > node2.folder {
            return thisGreaterThanThat
        }
        return thisEqualsThat
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
    func addChild(_ newChild: KnownFileNode) -> KnownFileNode {
        var i = 0
        var childNode: KnownFileNode?
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
    func addChild(_ child: KnownFileNode, at: Int) {
        child.parent = self
        if at >= children.count {
            children.append(child)
        } else {
            children.insert(child, at: at)
        }
    }
    
    /// Return the child at the specified index, or nil if bad index
    func getChild(at index: Int) -> KnownFileNode? {
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
    
    var hasChildren: Bool {
        return children.count > 0
    }
    
    /// Return the number of children for which this node is a parent
    var countChildren: Int {
        return children.count
    }
    
    /// Display values for debugging purposes. 
    func display() {
        print(" ")
        print("  Collector Node")
        print("    URL = \(url.absoluteString)")
        print("    Type = \(type)")
        print("    Base = \(base)")
        for segment in path {
            print("    Path = \(segment)")
        }
        print("    Folder = \(folder)")
        print("    # of Children = \(children.count)")
    }
    
}

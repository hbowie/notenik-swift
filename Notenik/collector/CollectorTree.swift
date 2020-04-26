//
//  CollectorTree.swift
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
import NotenikLib

/// A bunch of known Notenik Collections, organized by their location. 
class CollectorTree: Sequence {
    
    var root: CollectorNode!
    
    var baseList: [CollectorBase] = []
    
    let fm = FileManager.default
    let home = FileManager.default.homeDirectoryForCurrentUser
    var cloudNik: CloudNik!
    
    init() {
        print("Collector Tree init")
        root = CollectorNode(tree: self)
        
        var homeDir = home
        while homeDir.pathComponents.count > 2 {
            homeDir.deleteLastPathComponent()
        }
        let osBase = CollectorBase(name: "Home ~ ", url: homeDir)
        baseList.append(osBase)
        addBase(base: osBase)

        cloudNik = CloudNik.shared
        if cloudNik.url != nil {
            let cloudBase = CollectorBase(name: "iCloud Drive", url: cloudNik.url!)
            baseList.append(cloudBase)
            addBase(base: cloudBase)
            do {
                let iCloudContents = try fm.contentsOfDirectory(at: cloudNik.url!,
                                                             includingPropertiesForKeys: nil,
                                                             options: .skipsHiddenFiles)
                print("  - \(iCloudContents.count) entries in iCloud")
                for doc in iCloudContents {
                    print("  - contents of iCloud Drive = \(doc.path)")
                    // add(doc)
                }
            } catch {
                logError("Error reading contents of iCloud drive folder")
            }
        }
    }
    
    /// Add another Notenik Collection to the tree.
    func add(_ url: URL) {
        
        print("Adding url = \(url.path)")
        
        /// Make sure the passed URL actually points to a Notenik Collection
        var urlPointsToCollection = false
        if url.isFileURL && url.hasDirectoryPath {
            let folderPath = url.path
            let infoPath = FileUtils.joinPaths(path1: folderPath, path2: FileIO.infoFileName)
            let infoURL = URL(fileURLWithPath: infoPath)
            do {
                let reachable = try infoURL.checkResourceIsReachable()
                urlPointsToCollection = reachable
            } catch {
                urlPointsToCollection = false
            }
        }
        
        if !urlPointsToCollection { print("  - URL does not point to a collection") }
        
        guard urlPointsToCollection else { return }
        
        let urlPath = url.path
        var longestBase = CollectorBase()
        for base in baseList {
            if urlPath.starts(with: base.path) && base.count > longestBase.count {
                longestBase = base
            }
        }
        let collectionFileName = FileName(url)
        add(url: url, fileName: collectionFileName, base: longestBase, startingIndex: longestBase.count)
    }
    
    func addBase(base: CollectorBase) {
        let baseNode = CollectorNode(tree: self)
        baseNode.type = .folder
        baseNode.base = base
        _ = root.addChild(baseNode)
    }
    
    /// Add a new Collection to the tree, along with any nodes leading to it.
    /// - Parameters:
    ///   - url: The URL locating the collection.
    ///   - fileName: The FileName object locating the collection.
    ///   - base: The base description to be assigned to this collection.
    ///   - startingIndex: An index pointing to the first folder to be used as part
    ///                    of the collection's path.
    func add(url: URL, fileName: FileName, base: CollectorBase, startingIndex: Int) {
        
        // Add base node or obtain it if already added.
        let baseNode = CollectorNode(tree: self)
        baseNode.type = .folder
        baseNode.base = base
        var nextParent = root.addChild(baseNode)
        
        // Now add intervening path folders.
        let end = fileName.folders.count - 1
        for i in startingIndex ..< end {
            let nextChild = CollectorNode(tree: self)
            nextChild.type = .folder
            nextChild.base = base
            nextChild.populatePath(folders: fileName.folders, start: startingIndex, number: i - startingIndex)
            nextChild.folder = fileName.folders[i]
            nextParent = nextParent.addChild(nextChild)
        }
        
        // Finally, add the actual node representing the collection.
        let lastChild = CollectorNode(tree: self, url: url)
        lastChild.type = .collection
        lastChild.base = base
        lastChild.populatePath(folders: fileName.folders, start: startingIndex, number: end - startingIndex)
        lastChild.folder = fileName.folders[end]
        _ = nextParent.addChild(lastChild)
    }
    
    /// Log an information message.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectorTree",
                          level: .info,
                          message: msg)
    }
    
    /// Log an information message.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectorTree",
                          level: .error,
                          message: msg)
    }
    
    func makeIterator() -> CollectorIterator {
        return CollectorIterator(tree: self)
    }
    
    func add(more: [String], to: String) -> String {
        var added = to
        for toAdd in more {
            added = FileUtils.joinPaths(path1: added, path2: toAdd)
        }
        return added
    }
    
}

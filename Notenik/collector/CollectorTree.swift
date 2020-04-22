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
class CollectorTree {
    
    let root = CollectorNode()
    
    let fm = FileManager.default
    let home = FileManager.default.homeDirectoryForCurrentUser
    var homeFileName: FileName
    var sandBoxDocs: URL?
    var sandBoxPath = ""
    var sandBoxContents: [URL] = []
    
    init() {
        homeFileName = FileName(home)
        let sandBoxURLs = fm.urls(for: .documentDirectory, in: .userDomainMask)
        if sandBoxURLs.count > 0 {
            sandBoxDocs = sandBoxURLs[0]
            sandBoxPath = sandBoxDocs!.path
            
            let baseNode = CollectorNode()
            baseNode.type = .folder
            baseNode.base = "Sandbox"
            _ = root.addChild(baseNode)
            
        }
        logInfo("Home Directory for Current User = \(home.path)")
        logInfo("Sandbox docs path = \(sandBoxPath)")
        
        if sandBoxDocs != nil {
            do {
                try sandBoxContents = fm.contentsOfDirectory(at: sandBoxDocs!,
                                                             includingPropertiesForKeys: nil,
                                                             options: .skipsHiddenFiles)
                for doc in sandBoxContents {
                    add(doc)
                }
            } catch {
                logError("Error reading contents of Sandbox docs folder")
            }
        }
    }
    
    /// Add another Notenik Collection to the tree.
    func add(_ url: URL) {
        
        print(" ")
        print("Adding \(url) to the tree")
        
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
        
        let collectionFileName = FileName(url)
        if collectionFileName.folders.count > 2
            && homeFileName.folders.count >= 2
            && homeFileName.folders[0] == "Users"
            && collectionFileName.folders[0] == "Users"
            && homeFileName.folders[1] == collectionFileName.folders[1] {
            addWithinUserHome(url: url, fileName: collectionFileName)
        } else {
            addAwayFromHome(url: url, fileName: collectionFileName)
        }
    }
    
    func addWithinUserHome(url: URL, fileName: FileName) {
        if fileName.folders.count > 5
            && fileName.folders[2] == "Library"
            && fileName.folders[3] == "Mobile Documents"
            && fileName.folders[4] == "com~apple~CloudDocs" {
            add(url: url, fileName: fileName, base: "iCloud Drive", startingIndex: 5)
        } else if fileName.folders.count > 7
            && fileName.folders[2] == "Library"
            && fileName.folders[3] == "Containers"
            && fileName.folders[4] == "com.powersurgepub.notenik.macos"
            && fileName.folders[5] == "Data"
            && fileName.folders[6] == "Documents" {
            add(url: url, fileName: fileName, base: "Sandbox", startingIndex: 7)
        } else {
            add(url: url, fileName: fileName, base: "Home", startingIndex: 2)
        }
    }
    
    func addAwayFromHome(url: URL, fileName: FileName) {
        add(url: url, fileName: fileName, base: "/", startingIndex: 0)
    }
    
    /// Add a new Collection to the tree, along with any nodes leading to it.
    /// - Parameters:
    ///   - url: The URL locating the collection.
    ///   - fileName: The FileName object locating the collection.
    ///   - base: The base description to be assigned to this collection.
    ///   - startingIndex: An index pointing to the first folder to be used as part
    ///                    of the collection's path.
    func add(url: URL, fileName: FileName, base: String, startingIndex: Int) {
        
        print("  - base = \(base)")
        
        // Add base node or obtain it if already added.
        let baseNode = CollectorNode()
        baseNode.type = .folder
        baseNode.base = base
        var nextParent = root.addChild(baseNode)
        
        root.display()
        
        // Now add intervening path folders.
        var prevParent = nextParent
        let end = fileName.folders.count - 1
        for i in startingIndex ..< end {
            let nextChild = CollectorNode()
            nextChild.type = .folder
            nextChild.base = base
            nextChild.populatePath(folders: fileName.folders, start: startingIndex, number: i - startingIndex)
            nextChild.folder = fileName.folders[i]
            prevParent = nextParent
            nextParent = nextParent.addChild(nextChild)
            prevParent.display()
        }
        
        // Finally, add the actual node representing the collection.
        let lastChild = CollectorNode(url)
        lastChild.type = .collection
        lastChild.base = base
        lastChild.populatePath(folders: fileName.folders, start: startingIndex, number: end - startingIndex)
        lastChild.folder = fileName.folders[end]
        _ = nextParent.addChild(lastChild)
        nextParent.display()
        lastChild.display()
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
    
}

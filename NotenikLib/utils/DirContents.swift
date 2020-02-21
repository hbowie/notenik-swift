//
//  DirContents.swift
//  Notenik
//
//  Created by Herb Bowie on 2/7/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class to load, store and access the contents of a directory.
class DirContents {
    
    let fileManager = FileManager.default
    
    var dirPath = ""
    var dirEntries: [String] = []
    
    var skipDotFiles = true
    
    /// Optional initializer starting with two paths to be joined. 
    init?(path1: String, path2: String) {
        self.dirPath = FileUtils.joinPaths(path1: path1, path2: path2)
        do {
            dirEntries = try fileManager.contentsOfDirectory(atPath: dirPath)
        } catch {
            return nil
        }
    }
    
    /// Optional initializer starting with a single path.
    init?(path: String) {
        self.dirPath = path
        do {
            dirEntries = try fileManager.contentsOfDirectory(atPath: path)
        } catch {
            return nil
        }
    }
    
    /// Return the first directory entry ending with the indicated file extension. 
    func firstWithExtension(_ ext: String) -> (name: FileName?, index: Int) {
        return nextWithExtension(ext, start: 0)
    }
    
    /// Return the next directory entry ending with the passed extension.
    /// - Parameters:
    ///   - ext: Case will be ignored, and this parameter may or may not start with a period.
    ///   - start: The starting position for the search.
    /// - Returns:
    ///   - name: An optional filename, if another match was found.
    ///   - index: The position at which the match was found.
    func nextWithExtension(_ ext: String, start: Int) -> (name: FileName?, index: Int) {
        var i = start
        var ending = ""
        if ext.starts(with: ".") {
            ending = ext.lowercased()
        } else {
            ending = ".\(ext.lowercased())"
        }
        while i < dirEntries.count {
            let entry = dirEntries[i]
            if entry.starts(with: ".") && skipDotFiles {
                continue
            }
            let lowerEntry = entry.lowercased()
            if lowerEntry.hasSuffix(ending) {
                let completePath = FileUtils.joinPaths(path1: dirPath, path2: entry)
                return (FileName(completePath), i)
            }
            i += 1
        }
        return (nil, -1)
    }
    
    /// Return the first directory entry containing all of the passed words,
    /// ignoring case (upper or lower).
    func firstContaining(words: [String]) -> (name: FileName?, index: Int) {
        return nextContaining(words: words, start: 0)
    }
    
    /// Return the next directory entry containing all of the passed words,
    /// ignoring case (upper or lower).
    func nextContaining(words: [String], start: Int) -> (name: FileName?, index: Int) {
        var lowerWords: [String] = []
        for word in words {
            lowerWords.append(word.lowercased())
        }
        var i = start
        while i < dirEntries.count {
            let entry = dirEntries[i]
            if entry.starts(with: ".") && skipDotFiles {
                continue
            }
            let lowerEntry = entry.lowercased()
            var wordsFound = 0
            for word in lowerWords {
                if lowerEntry.contains(word) {
                    wordsFound += 1
                } else {
                    break
                }
            }
            if wordsFound == words.count {
                let completePath = FileUtils.joinPaths(path1: dirPath, path2: entry)
                return (FileName(completePath), i)
            }
            i += 1
        }
        return (nil, -1)
    }
    
}

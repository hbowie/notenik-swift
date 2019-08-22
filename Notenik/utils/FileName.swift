//
//  FileName.swift
//  Notenik
//
//  Created by Herb Bowie on 12/26/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class FileName: CustomStringConvertible {
    
    var fileNameStr = ""
    
    /// File extension without a leading dot
    var ext = ""
    
    /// Lowercase file extension, without a leading dot
    var extLower = ""
    
    var base = ""
    var baseLower = ""
    
    /// The path leading up to, but not including, any file name.
    var path = ""
    
    /// The lowest level folder in the supplied file name path.
    var folder = ""
    
    var folders: [Substring] = []
    
    
    var fileOrDir : FileOrDirectory = .unknown
    var readme = false
    var dotfile = false
    var template = false
    var noteExt = false
    var infofile = false
    var licenseFile = false
    var conflictedCopy = false
    var collectionParms = false
    
    var description: String {
        return fileNameStr
    }
    
    /// The file name, excluding the path to the folders containing the file. 
    var fileName: String {
        if base.count == 0 {
            return ""
        } else {
            return base + "." + ext
        }
    }
    
    /// Initialize with no initial value
    init() {
        
    }
    
    /// Initialize with a String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Initialize with a URL
    convenience init (_ url: URL) {
        self.init()
        set(url)
    }
    
    /// Set a new value with a URL providing the path
    func set(_ url: URL) {
        set(url.path)
    }
    
    /// Set a new value with a path stored in a String
    func set(_ value: String) {
        fileNameStr = value
        var slashCount = 0
        var dotCount = 0
        var index = fileNameStr.index(before: fileNameStr.endIndex)
        var lastIndex = fileNameStr.endIndex
        var dotIndex = fileNameStr.endIndex
        var c: Character = " "
        var i = fileNameStr.count - 1
        var pathEndIndex = fileNameStr.endIndex
        var folderStartIndex = fileNameStr.endIndex
        while i >= 0 {
            c = StringUtils.charAt(index: i, str: fileNameStr)
            
            if c == "." {
                if slashCount == 0 && dotCount == 0 {
                    setExt(String(fileNameStr[lastIndex..<fileNameStr.endIndex]))
                }
                dotCount += 1
                dotIndex = index
            } else if c == "/" {
                if dotCount == 0 {
                    fileOrDir = .directory
                }
                if slashCount == 0 && dotCount > 0 {
                    setBase(String(fileNameStr[lastIndex..<dotIndex])) 
                }
                if slashCount == 0 {
                    pathEndIndex = lastIndex
                }
                if slashCount == 1 {
                    folderStartIndex = lastIndex
                }
                slashCount += 1
            } else if i == 0 && slashCount == 0 && dotCount > 0 {
                setBase(String(fileNameStr[fileNameStr.startIndex..<dotIndex]))
            }
            
            i -= 1
            lastIndex = fileNameStr.index(before: lastIndex)
            if i >= 0 {
                index = fileNameStr.index(before: index)
            }
        }
        path = String(fileNameStr[fileNameStr.startIndex..<pathEndIndex])
        folders = path.split(separator: "/")
        if folderStartIndex < pathEndIndex {
            folder = String(fileNameStr[folderStartIndex..<pathEndIndex])
        }
    }
    
    func setExt(_ ext: String) {
        self.ext = ext
        extLower = ext.lowercased()
        if ext.count > 0 {
            fileOrDir = .file
        }
        switch extLower {
        case "txt", "text", "markdown", "md", "mdown", "mkdown", "mdtext", "nnk", "notenik":
            noteExt = true
        default:
            noteExt = false
        }
    }
    
    func setBase(_ base: String) {
        self.base = base
        licenseFile = (base == "LICENSE")
        collectionParms = (base == "Collection Parms")
        baseLower = base.lowercased()
        
        if base.count == 0 || base.hasPrefix(".") {
            dotfile = true
        } else if baseLower == "template" {
            template = true
        }
        
        
        let readMeStr = "readme"
        let infoStr = "info"
        var j = 0
        var k = 0
        readme = true
        infofile = true
        for c in baseLower {
            if StringUtils.isWhitespace(c) {
                // Ignore spaces
            } else if c == "-" {
                // Ignore hyphens
            } else if StringUtils.isAlpha(c) {
                if j < readMeStr.count && c == StringUtils.charAt(index: j, str: readMeStr) {
                    j += 1
                } else {
                    readme = false
                }
                if k < infoStr.count && c == StringUtils.charAt(index: k, str: infoStr) {
                    k += 1
                } else {
                    infofile = false
                }
            } else {
                readme = false
                infofile = false
            }
        }
        if j == 0 {
            readme = false
        }
        if k == 0 {
            infofile = false
        }
        if !noteExt {
            readme = false
            infofile = false
        }
    }
    
    /// Determine whether this file/folder is beneath/within the passed folder.
    ///
    /// - Parameter fn2: The possible parent to this file/folder.
    /// - Returns: True if this file is beneath fn2, otherwise false. 
    func isBeneath(_ fn2: FileName) -> Bool {
        guard folders.count > fn2.folders.count else { return false }
        var i = 0
        var matched = true
        while i < folders.count && i < fn2.folders.count && matched {
            let folder = String(folders[i])
            let folder2 = String(fn2.folders[i])
            if folder == folder2 {
                i += 1
            } else {
                matched = false
            }
        }
        return matched
    }
    
    /// Resolve a possible relative path relative to the path
    /// for this file name.
    ///
    /// - Parameter path: A possible relative path.
    /// - Returns: An absolute path.
    func resolveRelative(path: String) -> String {
        
        // If this is an absolute path, then don't mess with it
        guard !path.hasPrefix("/") else { return path }
        
        var resolved = ""
        var foldersToCopy = folders.count
        var looking = true
        var i = path.startIndex
        while i < path.endIndex && looking {
            let j = path.index(i, offsetBy: 3)
            if j <= path.endIndex {
                let nextThree = path[i..<j]
                if nextThree == "../" {
                    foldersToCopy -= 1
                    i = j
                } else {
                    looking = false
                }
            }
        }
        resolved.append("/")
        var folderIndex = 0
        while folderIndex < foldersToCopy {
            resolved.append(String(folders[folderIndex]))
            resolved.append("/")
            folderIndex += 1
        }
        resolved.append(String(path[i..<path.endIndex]))
        return resolved
    }
    
    /// Take an absolute path and return a path relative
    /// to the path for this file name.
    func makeRelative(path: String) -> String {
        
        // If this is already a relative path, then don't mess with it
        guard path.hasPrefix("/") else { return path }
        
        let fileName2 = FileName(path)
        
        var folderIndex = 0
        while (folderIndex < folders.count
            && folderIndex < fileName2.folders.count
            && folder(at: folderIndex) == fileName2.folder(at: folderIndex)) {
            folderIndex += 1
        }
        let matchedFolders = folderIndex
        var relPath = ""
        while folderIndex < folders.count {
            relPath.append("../")
            folderIndex += 1
        }
        folderIndex = matchedFolders
        while folderIndex < fileName2.folders.count {
            relPath.append(folder(at: folderIndex))
            relPath.append("/")
        }
        relPath.append(fileName)
        return relPath
    }
    
    func folder(at: Int) -> String {
        if at < 0 || at >= folders.count {
            return ""
        } else {
            return String(folders[at])
        }
    }
    
}

enum FileOrDirectory {
    case unknown
    case file
    case directory
}

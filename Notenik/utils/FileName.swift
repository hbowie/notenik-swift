//
//  FileName.swift
//  Notenik
//
//  Created by Herb Bowie on 12/26/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

class FileName: CustomStringConvertible {
    
    var fileNameStr = ""
    var ext = ""
    var extLower = ""
    var base = ""
    var baseLower = ""
    var fileOrDir : FileOrDirectory = .unknown
    var readme = false
    var dotfile = false
    var template = false
    var noteExt = false
    var infofile = false
    var conflictedCopy = false
    
    var description: String {
        return fileNameStr
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
        set(url.absoluteString)
    }
    
    /// Set a new value with a path stored in a String
    func set(_ value: String) {
        fileNameStr = value
        var slashCount = 0
        var dotCount = 0
        var i = fileNameStr.count - 1
        var index = fileNameStr.index(before: fileNameStr.endIndex)
        var lastIndex = fileNameStr.endIndex
        var dotIndex = fileNameStr.endIndex
        var c : Character = " "
        var lastC : Character = " "
        while i >= 0 {
            lastC = c
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

    }
    
    func setExt(_ ext : String) {
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
    
    func setBase(_ base : String) {
        self.base = base
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
    
}

enum FileOrDirectory {
    case unknown
    case file
    case directory
}

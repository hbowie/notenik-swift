//
//  DirReader.swift
//  Notenik
//
//  Created by Herb Bowie on 8/9/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// Read a Directory and return its contents as a series of rows. 
class DirReader: RowImporter {
    
    let fileManager         = FileManager.default
    
    var consumer:           RowConsumer?
    var workspace:          ScriptWorkspace?
    
    var maxDirDepth         = 1
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    var columnIndex         = 0
    
    init() {
        
    }
    
    /// Initialize the class with a Row Consumer
    func setContext(consumer: RowConsumer, workspace: ScriptWorkspace? = nil) {
        self.consumer = consumer
        self.workspace = workspace
    }
    
    /// Read the directory structure and break it down into
    /// fields and rows, returning each to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    /// - Returns: The number of rows returned.
    func read(fileURL: URL) {
        labels.append("Sort Key")
        var folderNumber = 1
        while folderNumber < maxDirDepth {
            labels.append("Folder\(folderNumber)")
            folderNumber += 1
        }
        labels.append("Path")
        labels.append("File Name")
        labels.append("Type")
        labels.append("English Name")
        labels.append("File Name w/o Ext")
        labels.append("File Ext")
        labels.append("File Size")
        labels.append("Last Mod Date")
        labels.append("Last Mod Time")
        labels.append("Word1")
        labels.append("Word2")
        labels.append("Word3")
        labels.append("Word4")
        labels.append("Word5")
        let startingSortKey = genSortKey(startingKey: "", addition: fileURL.path)
        readDirectory(fileURL, depth: 1, folders: [], sortkey: startingSortKey)
    }
    
    func readDirectory(_ dir: URL, depth: Int, folders: [String], sortkey: String) {
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: dir.path)
            for itemPath in dirContents {
                if itemPath == ".DS_Store" { continue }
                let itemFullPath = FileUtils.joinPaths(path1: dir.path,
                                                       path2: itemPath)
                let fileName = FileName(itemFullPath)
                let itemURL = URL(fileURLWithPath: itemFullPath)
                let dir = FileUtils.isDir(itemFullPath)
                fields = []
                
                // Put Sort Key
                let newSortKey = genSortKey(startingKey: sortkey, addition: itemPath)
                putField(newSortKey)
                
                // Put individual folders
                var path = ""
                var folderNumber = 1
                while folderNumber < maxDirDepth {
                    let folderIndex = folderNumber - 1
                    if folderIndex >= 0 && folderIndex < folders.count {
                        putField(folders[folderIndex])
                        if folderIndex > 0 {
                            path.append("/")
                        }
                        path.append(folders[folderIndex])
                    } else {
                        putField("")
                    }
                    folderNumber += 1
                }
                
                // Put Path
                putField(path)
                
                // Put File Name
                putField(itemPath)
                
                // Put Type
                if dir {
                    putField("Directory")
                } else {
                    putField("File")
                }
                
                // Put English Name
                if dir {
                    putField("")
                } else {
                    putField(fileName.base)
                }
                
                // Put File Name w/o Ext
                if dir {
                    putField("")
                } else {
                    putField(fileName.base)
                }
                
                // Put File Ext
                if dir {
                    putField("")
                } else {
                    putField(fileName.ext)
                }
                
                // Put File Size
                var modDate = ""
                var modTime = ""
                if dir {
                    putField("")
                } else {
                    do {
                        let attr = try fileManager.attributesOfItem(atPath: itemFullPath)
                        let fileSize = attr[FileAttributeKey.size]
                        let modificationDate = attr[FileAttributeKey.modificationDate]
                        if modificationDate != nil {
                            let modDateStr = String(describing: modificationDate!)
                            let modDateAndTime = modDateStr.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                            if modDateAndTime.count > 0 {
                                modDate = String(modDateAndTime[0])
                            }
                            if modDateAndTime.count > 1 {
                                modTime = String(modDateAndTime[1])
                            }
                        }
                        if fileSize != nil {
                            putField("\(fileSize!)")
                        } else {
                            putField("")
                        }
                    } catch {
                        logError("problems obtaining file attributes for \(itemFullPath)")
                    }
                }
                
                // Put Last Mod Date
                putField(modDate)
                
                // Put Last Mod Time
                putField(modTime)
                
                // Break up the file name into words
                var wordNumber = 1
                var word = ""
                for c in fileName.base {
                    if c.isLetter || c.isNumber {
                        word.append(c)
                    } else if word.count > 0 {
                        if wordNumber <= 5 {
                            putField(word)
                        }
                        wordNumber += 1
                        word = ""
                    }
                }
                if word.count > 0 {
                    if wordNumber <= 5 {
                        putField(word)
                    }
                    wordNumber += 1
                }
                
                while wordNumber <= 5 {
                    putField("")
                    wordNumber += 1
                }
                
                // Finish up this item
                consumer!.consumeRow(labels: labels, fields: fields)
                if dir && depth < maxDirDepth {
                    var moreFolders = folders
                    moreFolders.append(itemPath)
                    readDirectory(itemURL,
                                  depth: depth + 1,
                                  folders: moreFolders,
                                  sortkey: newSortKey)
                }
            }
        } catch {
            logError("Failed reading contents of directory: \(error)")
        }
    }
    
    func genSortKey(startingKey: String, addition: String) -> String {
        var sortKey = startingKey
        var pendingSpaces = 0
        if sortKey.count > 0 {
            pendingSpaces = 1
        }
        for c in addition {
            if c.isWhitespace {
                pendingSpaces += 1
            } else if c.isNumber {
                if pendingSpaces > 0 {
                    sortKey.append(" ")
                    pendingSpaces = 0
                }
                sortKey.append(c)
            } else if c.isLetter {
                if pendingSpaces > 0 {
                    sortKey.append(" ")
                    pendingSpaces = 0
                }
                sortKey.append(c.lowercased())
            } else {
                pendingSpaces += 1
            }
        }
        return sortKey
    }
    
    func putField(_ val: String) {
        consumer!.consumeField(label: labels[fields.count], value: val)
        fields.append(val)
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "DirReader",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
    
}

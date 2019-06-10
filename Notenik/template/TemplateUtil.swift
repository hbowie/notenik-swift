//
//  TemplateUtil.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Persistent data and utility methods. 
class TemplateUtil {
    
    var debug = false
    
    var templateURL: URL?
    var templateFileName = FileName()
    
    var dataFileName = FileName()
    
    var webRootURL: URL?
    var webRootFileName = FileName()
    
    var textOutURL: URL?
    var textOutFileName = FileName()
    var outputLines = ""
    var outputOpen = false
    var outputLineCount = 0
    
    /// A relative path from the location of the output file to the
    /// root of the enclosing website.
    var relativePathToRoot: String?
    
    var lineReader:  LineReader = BigStringReader("")
    var templateOK = false
    var lineCount  = 0
    
    var startCommand = "<<"
    var endCommand   = ">>"
    var startVar     = "<<"
    var endVar       = ">>"
    var startMods    = "&"
    
    var globals: Note
    
    var outputStage = OutputStage.front
    
    var skippingData = false
    
    init() {
        let globalsCollection = NoteCollection()
        globals = Note(collection: globalsCollection)
    }
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors. 
    func openTemplate(templateURL: URL) -> Bool {
        
        self.templateURL = templateURL
        templateFileName = FileName(templateURL)
        
        lineCount = 0
        do {
            let templateContents = try String(contentsOf: templateURL, encoding: .utf8)
            lineReader = BigStringReader(templateContents)
            lineReader.open()
            templateOK = true
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "TemplateUtil",
                              level: .error,
                              message: "Error reading Template from \(templateURL)")
            templateOK = false
        }
        return templateOK
    }
    
    /// Return the next template line, if there are any left.
    ///
    /// - Returns: The next template line, or nil at end.
    func nextTemplateLine() -> TemplateLine? {
        let nextLine = lineReader.readLine()
        if nextLine == nil {
            return nil
        } else {
            lineCount += 1
            return TemplateLine(text: nextLine!, util: self)
        }
    }
    
    /// Close the template. 
    func closeTemplate() {
        lineReader.close()
    }
    
    
    /// Open an output file, as requested from an open command.
    ///
    /// - Parameter filePath: The complete path to the desired output file.
    func openOutput(filePath: String) {
        closeOutput()
        print("Open Output at \(filePath)")
        let absFilePath = templateFileName.resolveRelative(path: filePath)
        print("Open Output at \(absFilePath)")
        textOutURL = URL(fileURLWithPath: absFilePath)
        textOutFileName = FileName(filePath)
        
        // If we have a web root, then figure out the relative path up to it
        // for possible later use.
        relativePathToRoot = ""
        if webRootURL != nil && textOutFileName.isBeneath(webRootFileName) {
            var folderCount = textOutFileName.folders.count
            while folderCount > webRootFileName.folders.count {
                relativePathToRoot!.append("../")
                folderCount -= 1
            }
        } else {
            relativePathToRoot = nil
        }
        outputOpen = true
    }
    
    /// Write one output line, with an optional trailing line break.
    func writeOutput(lineWithBreak: LineWithBreak) {
        outputLines.append(lineWithBreak.line)
        if lineWithBreak.lineBreak {
            outputLines.append("\n")
            outputLineCount += 1
        }
    }
    
    /// Close the output file, writing it out to disk if it was open.
    func closeOutput() {
        if outputOpen && textOutURL != nil {
            do {
                try outputLines.write(to: textOutURL!, atomically: false, encoding: .utf8)
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "TemplateUtil",
                                  level: .info,
                                  message: "\(outputLineCount) lines written to \(textOutURL!.path)")
            } catch {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "TemplateUtil",
                                  level: .fault,
                                  message: "Problems writing to output file at \(textOutURL!.path)")
            }
        }
        outputLines = ""
        outputLineCount = 0
        outputOpen = false
    }
    
    /// Replace any variables in the passed string with their current Note values.
    ///
    /// - Parameters:
    ///   - str: The string possibly containing variables.
    ///   - note: A Note containing data fields.
    /// - Returns: A line with variables replaced, with or without an ending line break.
    func replaceVariables(str: String, note: Note) -> LineWithBreak {
        
        let out = LineWithBreak()
        
        var lookingForStartVar = true
        var lookingForStartMods = false
        var lookingForEndVar = false
        
        var startWithDelim = str.startIndex
        var startPastDelim = str.startIndex
        var endAtDelim = str.startIndex
        var endPastDelim = str.startIndex
        var varName = ""
        var mods = ""
        var i = str.startIndex
        while i < str.endIndex {
            let char = str[i]
            if lookingForStartVar && strEqual(str: str, index: i, str2: startVar) {
                startWithDelim = i
                startPastDelim = str.index(i, offsetBy: startVar.count)
                i = startPastDelim
                lookingForStartVar = false
                lookingForStartMods = true
                lookingForEndVar = true
                varName = ""
                mods = ""
            } else if lookingForStartMods && strEqual(str: str, index: i, str2: startMods) {
                mods = ""
                i = str.index(i, offsetBy: startMods.count)
                lookingForStartMods = false
            } else if lookingForEndVar {
                if strEqual(str: str, index: i, str2: endVar) {
                    endAtDelim = i
                    endPastDelim = str.index(i, offsetBy: endVar.count)
                    appendVar(toLine: out, varName: varName, mods: mods, note: note)
                    i = endPastDelim
                    lookingForEndVar = false
                    lookingForStartMods = false
                    lookingForStartVar = true
                } else if lookingForStartMods {
                    varName.append(char)
                    i = str.index(i, offsetBy: 1)
                } else {
                    mods.append(char)
                    i = str.index(i, offsetBy: 1)
                }
            } else {
                out.line.append(char)
                i = str.index(i, offsetBy: 1)
            }
        }
        return out
    }
    
    /// See if the next few characters in the first string are equal to
    /// the entire contents of the second string.
    ///
    /// - Parameters:
    ///   - str: The string being indexed.
    ///   - index: An index into the first string.
    ///   - str2: The second string.
    /// - Returns: True if equal, false otherwise.
    func strEqual(str: String, index: String.Index, str2: String) -> Bool {
        guard str[index] == str2[str2.startIndex] else { return false }
        var strIndex = str.index(index, offsetBy: 1)
        var str2Index = str2.index(str2.startIndex, offsetBy: 1)
        while strIndex < str.endIndex && str2Index < str2.endIndex {
            if str[strIndex] != str2[str2Index] {
                return false
            }
            strIndex = str.index(strIndex, offsetBy: 1)
            str2Index = str2.index(str2Index, offsetBy: 1)
        }
        return true
    }
    
    func appendVar(toLine: LineWithBreak, varName: String, mods: String, note: Note) {
        let varNameCommon = StringUtils.toCommon(varName)
        
        var replacementValue: String?
        
        replacementValue = replaceVarWithValue(inLine: toLine, varName: varNameCommon, note: note)
        
        // See what modifiers we have
        for char in mods {
            
        }
        
        if replacementValue != nil {
            toLine.line.append(replacementValue!)
        }
        
    }
    
    func replaceVarWithValue(inLine: LineWithBreak, varName: String, note: Note) -> String? {

        var value: String?
        
        value = replaceSpecialVarWithValue(inLine: inLine, varNameCommon: varName)
        
        if value == nil {
            value = replaceVarWithValue(varName: varName, fromNote: globals)
        }
        
        if value == nil {
            value = replaceVarWithValue(varName: varName, fromNote: note)
        }
        
        return value
    }
    
    func replaceSpecialVarWithValue(inLine: LineWithBreak, varNameCommon: String) -> String? {
        switch varNameCommon {
        case "nobr":
            inLine.lineBreak = false
            return ""
        case "templatefilename":
            return templateFileName.fileName
        case "templateparent":
            return templateFileName.path
        case "datafilename":
            return dataFileName.fileName
        case "datafilebasename":
            return dataFileName.base
        case "dateparent":
            return dataFileName.path
        case "parentfolder":
            return dataFileName.folder
        case "today":
            return DateUtils.shared.ymdToday
        case "relative":
            if relativePathToRoot == nil {
                return nil
            } else {
                return relativePathToRoot
            }
        default:
            return nil
        }
    }
    
    /// Look for a replacement value for the passed field label.
    ///
    /// - Parameters:
    ///   - varName: The desire field label (aka variable name)
    ///   - fromNote: The Note instance containing the field values to be used.
    /// - Returns: The replacement value, if the variable name was found, otherwise nil.
    func replaceVarWithValue(varName: String, fromNote: Note) -> String? {
        let field = fromNote.getField(label: varName)
        if field == nil {
            return nil
        } else {
            return field!.value.value
        }
    }
}

enum OutputStage {
    case front
    case outer
    case loop
    case postLoop
}

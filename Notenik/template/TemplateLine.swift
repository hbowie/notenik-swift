//
//  TemplateLine.swift
//  Notenik
//
//  Created by Herb Bowie on 6/4/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One line of a template, along with metadata.
class TemplateLine {
    
    var util: TemplateUtil
    
    let delimiters = "\" =,;\t\r\n";
    
    var lineNumber = 0
    var text = ""
    var commandString: Substring = ""
    var command: TemplateCommand?
    var tokens = [Substring]()
    
    
    /// Initialize with required parameters
    ///
    /// - Parameters:
    ///   - text: The text making up the line.
    ///   - util: The instance of TemplateUtil that we are sharing.
    init(text: String, util: TemplateUtil) {
        self.text = StringUtils.trim(text)
        self.util = util
        lineNumber = util.lineCount
        analyzeLine()
    }
    
    /// Let's see what kind of line we have
    func analyzeLine() {
        if text.count > 2 && lineNumber == 1 {
            setCommandCharsFromFirstLine()
        }
        
        if text.hasPrefix(util.startCommand) && text.hasSuffix(util.endCommand) {
            analyzeApparentCommandLine()
        }
    }
    
    /// Found the right delimiters -- now let's look for a command
    func analyzeApparentCommandLine() {
        tokens = []
        let start = text.index(text.startIndex, offsetBy: util.startCommand.count)
        let end   = text.index(text.endIndex, offsetBy: (0 - util.endCommand.count))
        var index = start
        var tokenStart = text.startIndex
        var quoteChar: Character = "'"
        var withinQuotes = false
        while index < end {
            let char = text[index]
            if withinQuotes {
                if char == quoteChar {
                    addToken(start: tokenStart, end: index)
                    withinQuotes = false
                    tokenStart = text.startIndex
                }
            } else if char == "'" || char == "\"" {
                addToken(start: tokenStart, end: index)
                withinQuotes = true
                quoteChar = char
                tokenStart = text.index(index, offsetBy: 1)
            } else if char.isWhitespace || char == "," || char == ";" || char == ":" {
                addToken(start: tokenStart, end: index)
                tokenStart = text.startIndex
            } else if tokenStart == text.startIndex {
                tokenStart = index
            }
            index = text.index(index, offsetBy: 1)
        }
        addToken(start: tokenStart, end: index)
        command = TemplateCommand(rawValue: String(tokens[0]))
        if command != nil {
            switch command! {
            case .loop:
                util.outputStage = .postLoop
            case .nextrec:
                util.outputStage = .loop
            case .outer:
                util.outputStage = .outer
            default:
                break
            }
        }
    }
    
    
    /// Add another token to the list
    ///
    /// - Parameters:
    ///   - start: Index pointing to the start of the token.
    ///   - end: Index pointing to the end of the token.
    func addToken(start: String.Index, end: String.Index) {
        if start > text.startIndex && start <= end {
            let range = start..<end
            let token = text[range]
            tokens.append(token)
        }
    }
    
    /// Check the beginning of the first line and determine default command
    /// characters to use for this template.
    func setCommandCharsFromFirstLine() {
        if text.starts(with: "<?") {
            util.startCommand = "<?"
            util.endCommand   = "?>"
            util.startVar     = "=$"
            util.endVar       = "$="
            util.startMods    = "&"
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "TemplateLine",
                              level: .info,
                              message: "Template System using newer delimiters of <? ?> =$ $=")
        }
    }
    
    /// Generate output for this template line, given the fields passed in the Note.
    ///
    /// - Parameter note: The current Note being processed.
    func generateOutput(note: Note) {
        if command == nil {
            let lineWithBreak = util.replaceVariables(str: text, note: note)
            util.writeOutput(lineWithBreak: lineWithBreak)
        } else {
            processCommand(note: note)
        }
    }
    
    /// Process a Template Command Line
    func processCommand(note: Note) {
        switch command! {
        case .delims:
            processDelims()
        case .debug:
            processDebug()
        case .loop:
            break
        case .nextrec:
            break
        case .outer:
            break
        case .output:
            if !util.skippingData {
                processOutput(note: note)
            }
        default:
            processDefault()
        }
    }
    
    /// Process a Delims (delimiters) Command
    func processDelims() {
        var i = 0
        for token in tokens {
            switch i {
            case 1:
                util.startCommand = String(token)
            case 2:
                util.endCommand = String(token)
            case 3:
                util.startVar = String(token)
            case 4:
                util.endVar = String(token)
            case 5:
                util.startMods = String(token)
            default:
                break
            }
            i += 1
        }
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "TemplateLine",
                          level: .info,
                          message: "DELIM Command Results: " + util.startCommand
                                    + " " + util.endCommand
                                    + " " + util.startVar
                                    + " " + util.endVar
                                    + " " + util.startMods)
    }
    
    /// Process a Debug Command
    func processDebug() {
        util.debug = true
    }
    
    /// Process an Output Command
    func processOutput(note: Note) {
        util.openOutput(filePath: util.replaceVariables(str: String(tokens[1]), note: note).line)
    }
    
    func processDefault() {
        
    }
}

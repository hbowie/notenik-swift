//
//  WikiLinks.swift
//  Notenik
//
//  Created by Herb Bowie on 12/13/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikUtils

/// A parser for markdown text to look for and usefully convert wiki-style (double-bracket)
/// links to regular Markdown links.
class WikiLinks {
    
    let specialDomain = "https://ntnk.app/"
    var prefix = ""
    var suffix = ""
    var format: idFormat = .common
    var io: NotenikIO?
    var textOut = ""
    
    init() {
        prefix = specialDomain
    }
    
    /// Look for special note-to-note links.
    func parse(textIn: String, io: NotenikIO?) -> String {
        
        self.io = io
        textOut = ""
        
        var noChgStart = textIn.startIndex
        var noChgEnd = textIn.endIndex
        var textStart = textIn.endIndex
        var textEnd = textIn.endIndex
        var linkStart = textIn.endIndex
        var linkEnd = textIn.endIndex
        
        var singleBracketFound = false
        var doubleBracketFound = false
        
        var lastChar: Character = " "
        var currIx = textIn.startIndex
        
        for char in textIn {
            if char == "[" && lastChar != "\\" {
                if lastChar == "[" {
                    doubleBracketFound = true
                    singleBracketFound = false
                } else {
                    singleBracketFound = true
                    noChgEnd = currIx
                }
                textStart = textIn.index(after: currIx)
            } else if char == "]" && lastChar != "\\" {
                if lastChar != "]" {
                    textEnd = currIx
                }
                if lastChar == "]" && doubleBracketFound {
                    if noChgEnd > noChgStart {
                        let noChg = String(textIn[noChgStart..<noChgEnd])
                        textOut.append(noChg)
                    }
                    let text = String(textIn[textStart..<textEnd])
                    textOut = appendNoteLink(to: textOut, text: text, id: text)
                    noChgStart = textIn.index(after: currIx)
                    noChgEnd = textIn.endIndex
                    singleBracketFound = false
                    doubleBracketFound = false
                    linkStart = textIn.endIndex
                } else if lastChar != "]" && singleBracketFound {
                    textEnd = currIx
                }
            } else if char == "(" && singleBracketFound && lastChar == "]" {
                linkStart = textIn.index(after: currIx)
            } else if char == ")" && lastChar != "\\" && currIx > linkStart && singleBracketFound {
                linkEnd = currIx
                let id = String(textIn[linkStart..<linkEnd])
                if id.starts(with: "@") {
                    if noChgEnd > noChgStart {
                        let noChg = String(textIn[noChgStart..<noChgEnd])
                        textOut.append(noChg)
                    }
                    let idStart = textIn.index(linkStart, offsetBy: 1)
                    let offsetID = String(textIn[idStart..<linkEnd])
                    let text = String(textIn[textStart..<textEnd])
                    textOut = appendNoteLink(to: textOut, text: text, id: offsetID)
                    noChgStart = textIn.index(after: currIx)
                    noChgEnd = textIn.endIndex
                } else if id.starts(with: specialDomain) {
                    if noChgEnd > noChgStart {
                        let noChg = String(textIn[noChgStart..<noChgEnd])
                        textOut.append(noChg)
                    }
                    let idStart = textIn.index(linkStart, offsetBy: specialDomain.count)
                    let offsetID = String(textIn[idStart..<linkEnd])
                    let text = String(textIn[textStart..<textEnd])
                    textOut = appendNoteLink(to: textOut, text: text, id: offsetID)
                    noChgStart = textIn.index(after: currIx)
                    noChgEnd = textIn.endIndex
                } else {
                    noChgEnd = textIn.index(after: currIx)
                }
                singleBracketFound = false
                doubleBracketFound = false
                linkStart = textIn.endIndex
            } else if !singleBracketFound && !doubleBracketFound {
                noChgEnd = textIn.index(after: currIx)
            }
            lastChar = char
            currIx = textIn.index(after: currIx)
        }
        if noChgEnd > noChgStart {
            let noChg = String(textIn[noChgStart..<noChgEnd])
            textOut.append(noChg)
        }
        return textOut
    }
    
    /// Add a converted inter-note link to the output text.
    /// - Parameters:
    ///   - to: The existing output text.
    ///   - textIn: The text to be displayed.
    ///   - idIn: The target we're linking to. 
    func appendNoteLink(to: String, text textIn: String, id idIn: String) -> String {

        var formattedID = ""
        switch format {
        case .common:
            formattedID = StringUtils.toCommon(idIn)
        case .fileName:
            formattedID = StringUtils.toCommonFileName(idIn)
        }
        
        var text = textIn
        if io != nil {
            if textIn == idIn && formattedID.count < 15 && formattedID.count > 11 {
                let target = io!.getNote(forTimestamp: formattedID)
                if target != nil {
                    text = target!.title.value
                }
            }
        }
        let link = "[" + text + "](" + prefix + formattedID + suffix + ")"
        return to + link
    }
    
    /// The formatting to be applied to the ID. 
    enum idFormat {
        case common
        case fileName
    }
}

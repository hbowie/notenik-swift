//
//  Markdown.swift
//  Notenik
//
//  Created by Herb Bowie on 12/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import Down
import Ink

// Convert Markdown to HTML, using the user's favorite parser.
class Markdown {
    
    var notenikIO: NotenikIO?
    var preParser = false
    var md = ""
    var html = ""
    var ok = true
    
    var parserID = "down"
    
    /// Parse the markdown text in md and place the result into html.
    /// Note that all instance properties must be set and accessed before and after
    /// the call to parse.
    func parse() {
        ok = true
        html = ""
        if notenikIO != nil {
            if notenikIO!.collection != nil {
                preParser = notenikIO!.collection!.doubleBracketParsing
            }
        }
        if preParser {
            preParse()
        }
        parserID = AppPrefs.shared.markdownParser
        switch parserID {
        case "down":
            let down = Down(markdownString: md)
            do {
                html = try down.toHTML(DownOptions.smartUnsafe)
            } catch {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "MarkdownParser",
                                  level: .error,
                                  message: "Down parser threw an error")
                ok = false
            }
        case "ink":
            let ink = MarkdownParser()
            html = ink.html(from: md)
        default:
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "MarkdownParser",
                              level: .error,
                              message: "Parser ID of \(parserID) is unrecognized")
            ok = false
        }
    }
    
    /// Look for special note-to-note links.
    func preParse() {
        let pre = md
        md = ""
        
        var noChgStart = pre.startIndex
        var noChgEnd = pre.endIndex
        var textStart = pre.endIndex
        var textEnd = pre.endIndex
        var linkStart = pre.endIndex
        var linkEnd = pre.endIndex
        
        var singleBracketFound = false
        var doubleBracketFound = false
        
        var lastChar: Character = " "
        var currIx = pre.startIndex
        
        for char in pre {
            if char == "[" && lastChar != "\\" {
                if lastChar == "[" {
                    doubleBracketFound = true
                    singleBracketFound = false
                } else {
                    singleBracketFound = true
                    noChgEnd = currIx
                }
                textStart = pre.index(after: currIx)
            } else if char == "]" && lastChar != "\\" {
                if lastChar != "]" {
                    textEnd = currIx
                }
                if lastChar == "]" && doubleBracketFound {
                    if noChgEnd > noChgStart {
                        let noChg = String(pre[noChgStart..<noChgEnd])
                        md.append(noChg)
                    }
                    let text = String(pre[textStart..<textEnd])
                    md = appendNoteLink(to: md, text: text, id: text)
                    noChgStart = pre.index(after: currIx)
                    noChgEnd = pre.endIndex
                    singleBracketFound = false
                    doubleBracketFound = false
                    linkStart = pre.endIndex
                } else if lastChar != "]" && singleBracketFound {
                    textEnd = currIx
                }
            } else if char == "(" && singleBracketFound && lastChar == "]" {
                linkStart = pre.index(after: currIx)
            } else if char == ")" && lastChar != "\\" && currIx > linkStart && singleBracketFound {
                linkEnd = currIx
                let id = String(pre[linkStart..<linkEnd])
                if id.starts(with: "@") {
                    if noChgEnd > noChgStart {
                        let noChg = String(pre[noChgStart..<noChgEnd])
                        md.append(noChg)
                    }
                    let text = String(pre[textStart..<textEnd])
                    md = appendNoteLink(to: md, text: text, id: id)
                    noChgStart = pre.index(after: currIx)
                    noChgEnd = pre.endIndex
                } else {
                    noChgEnd = pre.index(after: currIx)
                }
                singleBracketFound = false
                doubleBracketFound = false
                linkStart = pre.endIndex
            } else if !singleBracketFound && !doubleBracketFound {
                noChgEnd = pre.index(after: currIx)
            }
            lastChar = char
            currIx = pre.index(after: currIx)
        }
        if noChgEnd > noChgStart {
            let noChg = String(pre[noChgStart..<noChgEnd])
            md.append(noChg)
        }
    }
    
    func appendNoteLink(to: String, text textIn: String, id idIn: String) -> String {
        var text = textIn
        let id = StringUtils.toCommon(idIn)
        if notenikIO != nil {
            if textIn == idIn && id.count < 15 && id.count > 11 {
                let target = notenikIO!.getNote(forTimestamp: id)
                if target != nil {
                    text = target!.title.value
                }
            }
        }
        let link = "[\(text)](https://ntnk.app/\(id))"
        return to + link
    }
}

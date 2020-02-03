//
//  Markedup.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object capable of generating marked up text (currently HTML or Markdown)
class Markedup: CustomStringConvertible {
    
    var notenikIO: NotenikIO?
    
    var format: MarkedupFormat = .htmlFragment
    var code = ""
    
    var lastCharWasWhiteSpace = true
    var lastCharWasEmDash = false
    var startingQuote = true
    var whiteSpacePending = false
    var lastCharWasEmphasis = false
    var emphasisPending = 0
    var lastEmphasisChar: Character = " "
    var listInProgress: Character = " "
    var defInProgress: Character = " "
    
    var spacesPerIndent = 2
    var currentIndent = 0
    
    convenience init (format: MarkedupFormat) {
        self.init()
        self.format = format
    }
    
    /// Return the description, used as the String value for the object
    var description: String {
        return code
    }
    
    func flushCode() {
        code = ""
    }
    
    func startDoc(withTitle title: String?, withCSS css: String?) {
        currentIndent = 0
        switch format {
        case .htmlDoc:
            writeLine("<!DOCTYPE html>")
            writeLine("<html lang=\"en\">")
            writeLine("<head>")
            writeLine("<meta charset=\"utf-8\" />")
            if title != nil && title!.count > 0 {
                writeLine("<title>\(title!)</title>")
            }
            writeLine("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />")
            if css != nil && css!.count > 0 {
                writeLine("<style>")
                writeLine(css!)
                writeLine("</style>")
            }
            writeLine("</head>")
            writeLine("<body>")
        case .netscapeBookmarks:
            writeLine("<!DOCTYPE NETSCAPE-Bookmark-file-1>")
            increaseIndent()
            writeLine("<HTML>")
            writeLine("<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">")
            writeLine("<Title>Bookmarks</Title>")
            writeLine("<H1>Bookmarks</H1>")
            writeLine("<DL><p>")
            increaseIndent()
        default:
            break
        }
    }
    
    func finishDoc() {
        switch format {
        case .htmlDoc:
            writeLine("</body>")
            writeLine("</html>")
        case .netscapeBookmarks:
            writeLine("</DL>")
            decreaseIndent()
            writeLine("</HTML>")
            decreaseIndent()
        case .htmlFragment, .markdown:
            break
        }
    }
    
    func startDiv(klass: String?) {
        if format == .htmlFragment || format == .htmlDoc {
            if code.count > 0 {
                newLine()
            }
            code.append("<div")
            if klass != nil && klass!.count > 0 {
                self.code.append(" class=\"\(klass!)\"")
            }
            code.append(">")
            newLine()
        }
    }
    
    func finishDiv() {
        if format == .htmlFragment || format == .htmlDoc {
            writeLine("</div>")
        }
    }
    
    func startBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<blockquote>")
        default:
            break
        }
    }
    
    func finishBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</blockquote>")
        default:
            break
        }
    }
    
    func startOrderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<ol")
            if klass != nil && klass!.count > 0 {
                code.append(" class=\"\(klass!)\"")
            }
            code.append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
        listInProgress = "o"
    }
    
    func finishOrderedList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</ol>")
        default:
            break
        }
        listInProgress = " "
    }
    
    func startUnorderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<ul")
            if klass != nil && klass!.count > 0 {
                code.append(" class=\"\(klass!)\"")
            }
            code.append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
        listInProgress = "u"
    }
    
    func finishUnorderedList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</ul>")
        default:
            break
        }
        listInProgress = " "
    }
    
    func startDefinitionList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<dl")
            if klass != nil && klass!.count > 0 {
                code.append(" class=\"\(klass!)\"")
            }
            code.append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
        listInProgress = "d"
        defInProgress = " "
    }
    
    func startDefTerm() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<dt>")
        case .markdown:
            break
        }
        defInProgress = "t"
    }
    
    func finishDefTerm() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            code.append("</dt>")
        case .markdown:
            break
        }
        defInProgress = " "
    }
    
    func startDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            code.append("<dd>")
        case .markdown:
            break
        }
        defInProgress = "d"
    }
    
    func finishDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            code.append("</dd>")
        case .markdown:
            break
        }
        defInProgress = " "
    }
    
    func finishDefinitionList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</dl>")
        default:
            break
        }
        listInProgress = " "
    }
    
    func startListItem() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if code.count > 0 {
                newLine()
            }
            code.append("<li>")
        case .markdown:
            switch listInProgress {
            case "u":
                code.append("* ")
            case "o":
                code.append("1. ")
            default:
                break
            }
        }
    }
    
    func finishListItem() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</li>")
        case .markdown:
            break
        }
    }
    
    func paragraph(text: String) {
        startParagraph()
        write(text)
        finishParagraph()
    }
    
    func startParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if code.count > 0 {
                newLine()
            }
            code.append("<p>")
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
    }
    
    func startParagraph(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if code.count > 0 {
                newLine()
            }
            code.append("<p")
            if klass != nil && klass!.count > 0 {
                self.code.append(" class=\"\(klass!)\"")
            }
            code.append(">")
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
    }
    
    func lineBreak() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            code.append("<br />")
            newLine()
        case .markdown:
            append("  ")
            newLine()
        }
    }
    
    func finishParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</p>")
            newLine()
        case .markdown:
            newLine()
        }
    }
    
    func startStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<strong>")
        case .markdown:
            code.append("**")
        }
        emphasisPending = 2
        lastCharWasEmphasis = true
    }
    
    func finishStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</strong>")
        case .markdown:
            code.append("**")
        }
        emphasisPending = 0
    }
    
    func startEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<em>")
        case .markdown:
            code.append("*")
        }
        emphasisPending = 1
    }
    
    func finishEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</em>")
        case .markdown:
            code.append("*")
        }
        emphasisPending = 0
    }
    
    func startItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<i>")
        case .markdown:
            code.append("*")
        }
        emphasisPending = 1
    }
    
    func finishItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</i>")
        case .markdown:
            code.append("*")
        }
        emphasisPending = 0
    }
    
    func startCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<cite>")
        case .markdown:
            code.append("*")
        }
    }
    
    func finishCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</cite>")
        case .markdown:
            code.append("*")
        }
    }
    
    func heading(level: Int, text: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<h\(level)>\(text)</h\(level)>")
        case .markdown:
            writeLine(String(repeating: "#", count: level) + " " + text)
        }
    }
    
    func startHeading(level: Int) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("<h\(level)>")
        case .markdown:
            write(String(repeating: "#", count: level) + " ")
        }
    }
    
    func finishHeading(level: Int) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</h\(level)>")
        case .markdown:
            newLine()
        }
    }
    
    func link(text: String, path: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<a href=\"" + path + "\">" + text + "</a>")
        case .markdown:
            code.append("[" + text + "](" + path + ")")
        }
    }
    
    func startLink(path: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<a href=\"" + path + "\">")
        case .markdown:
            code.append("[")
        }
    }
    
    func finishLink() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("</a>")
        case .markdown:
            break
        }
    }
    
    func horizontalRule() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("<hr>")
        case .markdown:
            newLine()
            code.append("---")
            newLine()
        }
    }
    
    func codeBlock(_ block: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<pre><code>")
            writeLine(block)
            writeLine("</code></pre>")
        case .markdown:
            let reader: LineReader = BigStringReader(block)
            reader.open()
            var line = reader.readLine()
            while line != nil {
                code.append("    " + line! + "\n")
                line = reader.readLine()
            }
            reader.close()
        }
    }
    
    /// Enclose a value in a span tag, with a class.
    ///
    /// - Parameters:
    ///   - value: The value to be enclosed between starting and ending span tags.
    ///   - klass: The class to be embedded in the starting span tag.
    ///   - prefix: A prefix to precede the span.
    ///   - suffix: A suffix to follow the span. 
    func spanConditional(value: String, klass: String, prefix: String, suffix: String, tag: String = "span") {
        if value.count > 0 && value.lowercased() != "unknown" {
            code.append(prefix)
            code.append("<\(tag) class=\'\(klass)\'>")
            code.append(value)
            code.append("</\(tag)>")
            code.append(suffix)
        }
    }
    
    func leftDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8220;")
        case .markdown:
            code.append("\"")
        }
    }
    
    func rightDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8221;")
        case .markdown:
            code.append("\"")
        }
    }
    
    func leftSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8216;")
        case .markdown:
            code.append("'")
        }
    }
    
    func rightSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8217;")
        case .markdown:
            code.append("'")
        }
    }
    
    func shortDash() {
        writeEnDash()
    }
    
    func longDash() {
        writeEmDash()
    }
    
    func increaseIndent() {
        currentIndent += spacesPerIndent
    }
    
    func decreaseIndent() {
        currentIndent -= spacesPerIndent
        if currentIndent < 0 {
            currentIndent = 0
        }
    }
    
    func writeLine(_ text: String) {
        indent()
        write(text)
        newLine()
    }
    
    func indent() {
        write(String(repeating: " ", count: currentIndent))
    }
    
    func write(_ text: String) {
        code.append(text)
    }
    
    func newLine() {
        code.append("\n")
    }
    
    func append(_ more: String) {
        code.append(more)
    }
    
    func append(_ char: Character) {
        code.append(char)
    }
    
    func append(markdown: String) {
        switch format {
        case.htmlFragment, .htmlDoc, .netscapeBookmarks:
            let downer = Markdown()
            downer.notenikIO = notenikIO
            downer.md = markdown
            downer.parse()
            if downer.ok {
                code.append(downer.html)
            } else {
                code.append(markdown)
            }
        case.markdown:
            code.append(markdown)
        }
    }
    
    /// Parse the passed text line, using a subset of Markdown syntax, and convert it
    /// to the desired output format.
    ///
    /// - Parameters:
    ///   - text: The text to be parsed.
    ///   - startingLastCharWasWhiteSpace: An indicator of whether the last character
    ///                                    was some sort of white space.
    func parse(text: String, startingLastCharWasWhiteSpace: Bool) {
        startDoc(withTitle: nil, withCSS: nil)
        lastCharWasWhiteSpace = startingLastCharWasWhiteSpace
        whiteSpacePending = true
        if lastCharWasWhiteSpace {
            whiteSpacePending = false
        }
        emphasisPending = 0
        lastCharWasEmDash = false
        if whiteSpacePending {
            writeSpace()
        }
        
        var index = text.startIndex
        for char in text {
            
            // If this is the second char in the -- sequence, then just
            // let it go by, since we already wrote out the em dash.
            if lastCharWasEmDash {
                lastCharWasEmDash = false
                lastCharWasWhiteSpace = false
            }
                
                // If we have white space, write out only one space
            else if char.isWhitespace {
                writeSpace()
            }
                
                // If we have an en dash, replace it with an appropriate entity
            else if (char == "-" && lastCharWasWhiteSpace
                && text.charAtOffset(index: index, offsetBy: 1).isWhitespace) {
                writeEnDash()
            }
                
                // If we have two dashes, replace them witn an em dash
            else if char == "-" && text.charAtOffset(index: index, offsetBy: 1) == "-" {
                writeEmDash()
            }
                
                // If we have a double quotion mark, replace it with a smart quote
            else if char == "\"" {
                writeDoubleQuote()
            }
                
                // If we have a single quotation mark, replace it with the appropriate entity
            else if char == "'" {
                if text.charAtOffset(index: index, offsetBy: 1).isLetter {
                    writeApostrophe()
                } else {
                    writeSingleQuote()
                }
            }
                
                // If an isolated ampersand, replace it with an appropriate entity
            else if char == "&" && text.charAtOffset(index: index, offsetBy: 1).isWhitespace {
                writeAmpersand()
            }
                
                // Check for emphasis
            else if char == "*" || char == "_" {
                if lastCharWasEmphasis {
                    // If this is the second char in the emphasis sequence, then just let
                    // it go by, since we already wrote out the appropriate html.
                    lastCharWasEmphasis = false
                } else if (emphasisPending == 1
                    && char == lastEmphasisChar
                    && !lastCharWasWhiteSpace) {
                    finishEmphasis()
                } else if (emphasisPending == 2
                    && char == lastEmphasisChar
                    && text.charAtOffset(index: index, offsetBy: 1) == lastEmphasisChar
                    && !lastCharWasWhiteSpace) {
                    finishStrong()
                    lastCharWasEmphasis = true
                } else if (emphasisPending == 0
                    && text.charAtOffset(index: index, offsetBy: 1) == char
                    && !text.charAtOffset(index: index, offsetBy: 2).isWhitespace) {
                    startStrong()
                    lastEmphasisChar = char
                } else if (emphasisPending == 0
                    && !text.charAtOffset(index: index, offsetBy: 1).isWhitespace) {
                    startEmphasis()
                    lastEmphasisChar = char
                } else {
                    lastCharWasWhiteSpace = false
                    lastCharWasEmDash  = false
                    code.append(char)
                }
            } else {
                lastCharWasWhiteSpace = false
                lastCharWasEmDash = false
                code.append(char)
            }
            index = text.index(after: index)
        }
        finishDoc()
    }
    
    /// Write out a space, but don't write more than one in a row
    func writeSpace() {
        lastCharWasEmDash = false
        whiteSpacePending = false
        if !lastCharWasWhiteSpace {
            code.append(" ")
            lastCharWasWhiteSpace = true
        }
    }
    
    /// Write out an en dash
    func writeEnDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8211;")
        case .markdown:
            code.append("-")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeEmDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&#8212;")
        case .markdown:
            code.append("--")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = true
    }
    
    func ellipsis() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            code.append("&#8230;")
        case .markdown:
            code.append("...")
        }
    }
    
    func writeDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                code.append("&#8220;")
                startingQuote = false
            } else {
                code.append("&#8221;")
                startingQuote = true
            }
        case .markdown:
            code.append("\"")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeApostrophe() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&apos;")
        case .markdown:
            code.append("'")
        }
    }
    
    func writeSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                code.append("&#8216;")
                startingQuote = false
            } else {
                code.append("&#8217;")
                startingQuote = true
            }
        case .markdown:
            code.append("'")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeAmpersand() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            code.append("&amp;")
        case .markdown:
            code.append("&")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
}
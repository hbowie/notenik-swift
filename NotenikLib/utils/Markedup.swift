//
//  Markedup.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
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
    
    let xmlConverter = StringConverter()
    
    init() {
        xmlConverter.addXML()
    }
    
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
    
    func templateNextRec() {
        writeLine("<?nextrec?>")
    }
    
    func templateLoop() {
        writeLine("<?loop?>")
    }
    
    func templateOutput(filename: String) {
        writeLine("<?output \"\(filename)\" ?>")
    }
    
    func templateIfField(fieldname: String) {
        writeLine("<?if \"\(fieldname)\" ?>")
    }
    
    func templateEndIf() {
        writeLine("<?endif?>")
    }
    
    /// Start the document with appropriate markup.
    /// - Parameters:
    ///   - title: The page title, if one is available.
    ///   - css: The CSS to be used, or the filename containing the CSS.
    ///   - linkToFile: If true, then interpet the CSS string as a file name, rather than the actual CSS. 
    func startDoc(withTitle title: String?, withCSS css: String?, linkToFile: Bool = false) {
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
                if linkToFile {
                    writeLine("<link rel=\"stylesheet\" href=\"\(css!)\" type=\"text/css\" />")
                } else {
                    writeLine("<style>")
                    writeLine(css!)
                    writeLine("</style>")
                }
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
        case .opml:
            writeLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            writeLine("<opml version=\"2.0\">")
            writeLine("<head>")
            if title != nil {
                writeLine("<title>\(title!)</title>")
            }
            writeLine("</head>")
            writeLine("<body>")
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
        case .opml:
            writeLine("</body>")
            writeLine("</opml>")
        case .htmlFragment, .markdown:
            break
        }
    }
    
    func startDiv(klass: String?) {
        if format == .htmlFragment || format == .htmlDoc {
            ensureNewLine()
            append("<div")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
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
            append("<ol")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
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
            append("<ul")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
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
    
    func startPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    func finishPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    func startCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("<code>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    func finishCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("</code>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    func startDefinitionList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<dl")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
        }
        listInProgress = "d"
        defInProgress = " "
    }
    
    func startDefTerm() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<dt>")
        case .markdown:
            break
        case .opml:
            break
        }
        defInProgress = "t"
    }
    
    func finishDefTerm() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("</dt>")
        case .markdown:
            break
        case .opml:
            break
        }
        defInProgress = " "
    }
    
    func startDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("<dd>")
        case .markdown:
            break
        case .opml:
            break
        }
        defInProgress = "d"
    }
    
    func finishDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("</dd>")
        case .markdown:
            break
        case .opml:
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
            ensureNewLine()
            append("<li>")
        case .markdown:
            switch listInProgress {
            case "u":
                append("* ")
            case "o":
                append("1. ")
            default:
                break
            }
        case .opml:
            break
        }
    }
    
    func finishListItem() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</li>")
            newLine()
        case .markdown:
            break
        case .opml:
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
            ensureNewLine()
            append("<p>")
        case .markdown:
            ensureNewLine()
        case .opml:
            break
        }
    }
    
    func startParagraph(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            ensureNewLine()
            append("<p")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
        case .markdown:
            ensureNewLine()
        case .opml:
            break
        }
    }
    
    func lineBreak() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("<br />")
            newLine()
        case .markdown:
            append("  ")
            newLine()
        case .opml:
            break
        }
    }
    
    func finishParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</p>")
            newLine()
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    func startStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<strong>")
        case .markdown:
            append("**")
        case .opml:
            break
        }
        emphasisPending = 2
        lastCharWasEmphasis = true
    }
    
    func finishStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</strong>")
        case .markdown:
            append("**")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    func startEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<em>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 1
    }
    
    func finishEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</em>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    func startItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<i>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 1
    }
    
    func finishItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</i>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    func startCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<cite>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    func finishCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</cite>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    func heading(level: Int, text: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<h\(level)>\(text)</h\(level)>")
        case .markdown:
            writeLine(String(repeating: "#", count: level) + " " + text)
        case .opml:
            break
        }
    }
    
    func startHeading(level: Int) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("<h\(level)>")
        case .markdown:
            write(String(repeating: "#", count: level) + " ")
        case .opml:
            break
        }
    }
    
    func finishHeading(level: Int) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</h\(level)>")
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    func link(text: String, path: String, title: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            append(">" + text + "</a>")
        case .markdown:
            append("[" + text + "](" + path + ")")
        case .opml:
            break
        }
    }
    
    func startLink(path: String, title: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            append(">")
        case .markdown:
            append("[")
        case .opml:
            break
        }
    }
    
    func finishLink() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</a>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    func horizontalRule() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<hr>")
        case .markdown:
            newLine()
            append("---")
            newLine()
        case .opml:
            break
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
                append("    " + line! + "\n")
                line = reader.readLine()
            }
            reader.close()
        case .opml:
            break
        }
    }
    
    /// Open up the starting outline tag.
    func startOutlineOpen(_ text: String) {
        append("<outline text=\"")
        appendXML(text)
        append("\"")
    }
    
    func addOutlineAttribute(label: String, value: String) {
        append(" \(label)=\"")
        appendXML(value)
        append("\"")
    }
    
    /// Close out the starting outline tag.
    func startOutlineClose(finishToo: Bool = true) {
        if finishToo {
            append("/")
        }
        append(">")
        newLine()
    }
    
    /// Finish up an open OPML outline.
    func finishOutline() {
        writeLine("</outline>")
    }
    
    /// Encode restricted characters as XML entities.
    func appendXML(_ text: String) {
        append(xmlConverter.convert(from: text))
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
            append(prefix)
            append("<\(tag) class=\'\(klass)\'>")
            append(value)
            append("</\(tag)>")
            append(suffix)
        }
    }
    
    func leftDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8220;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    func rightDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8221;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    func leftSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8216;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    func rightSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8217;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
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
        append(text)
    }
    
    var newLineStarted = true
    
    func ensureNewLine() {
        if !newLineStarted {
            newLine()
        }
    }
    
    func newLine() {
        code.append("\n")
        newLineStarted = true
    }
    
    func append(_ more: String) {
        code.append(more)
        newLineStarted = false
    }
    
    func append(_ char: Character) {
        code.append(char)
        newLineStarted = false
    }
    
    func append(markdown: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            let downer = Markdown()
            downer.notenikIO = notenikIO
            downer.md = markdown
            downer.parse()
            if downer.ok {
                append(downer.html)
            } else {
                append(markdown)
            }
        case .markdown:
            append(markdown)
        case .opml:
            break
        }
        newLineStarted = false
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
                    append(char)
                }
            } else {
                lastCharWasWhiteSpace = false
                lastCharWasEmDash = false
                append(char)
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
            append(" ")
            lastCharWasWhiteSpace = true
        }
        newLineStarted = false
    }
    
    /// Write out an en dash
    func writeEnDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8211;")
        case .markdown:
            append("-")
        case .opml:
            append("-")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeEmDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8212;")
        case .markdown:
            append("--")
        case .opml:
            append("--")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = true
    }
    
    func ellipsis() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("&#8230;")
        case .markdown:
            append("...")
        case .opml:
            append("...")
        }
    }
    
    func writeDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                append("&#8220;")
                startingQuote = false
            } else {
                append("&#8221;")
                startingQuote = true
            }
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeApostrophe() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&apos;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    func writeSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                append("&#8216;")
                startingQuote = false
            } else {
                append("&#8217;")
                startingQuote = true
            }
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeLeftAngleBracket() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&lt;")
        case .markdown:
            append("<")
        case .opml:
            append("&lt;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeRightAngleBracket() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&gt;")
        case .markdown:
            append(">")
        case .opml:
            append("&gt;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeAmpersand() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&amp;")
        case .markdown:
            append("&")
        case .opml:
            append("&amp;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
}

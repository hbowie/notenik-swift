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

import Down
import Foundation

/// An object capable of generating marked up text (currently HTML or Markdown)
class Markedup: CustomStringConvertible {
    
    var format: MarkedupFormat = .htmlFragment
    var code = ""
    
    convenience init (format: MarkedupFormat) {
        self.init()
        self.format = format
    }
    
    /// Return the description, used as the String value for the object
    var description: String {
        return code
    }
    
    func startDoc(withTitle title: String?) {
        switch format {
        case .htmlDoc:
            code.append("<html>")
            code.append("<head>")
            if title != nil && title!.count > 0 {
                code.append("<title>\(title!)</title>")
            }
            code.append("</head>")
            code.append("<body>")
        default:
            let x = 0
        }
    }
    
    func startParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("<p>")
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
    }
    
    func startStrong() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("<strong>")
        case .markdown:
            code.append("**")
        }
    }
    
    func finishStrong() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("</strong>")
        case .markdown:
            code.append("**")
        }
    }
    
    func startEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("<em>")
        case .markdown:
            code.append("*")
        }
    }
    
    func finishEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("</em>")
        case .markdown:
            code.append("*")
        }
    }
    
    func link(text: String, path: String) {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("<a href=\"" + path + "\">" + text + "</a>")
        case .markdown:
            code.append("[" + text + "](" + path + ")")
        }
    }
    
    func codeBlock(_ block: String) {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("<pre><code>")
            code.append(block)
            code.append("</code></pre>")
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
    
    func finishParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("</p>")
        case .markdown:
            newLine()
        }
    }
    
    func newLine() {
        code.append("\n")
    }
    
    func append(_ more: String) {
        code.append(more)
    }
    
    func append(markdown: String) {
        switch format {
        case.htmlFragment, .htmlDoc:
            let down = Down(markdownString: markdown)
            var html = ""
            do {
                html = try down.toHTML()
                code.append(html)
            } catch {
                print("Markdown parser threw an error!")
                code.append(markdown)
            }
        case.markdown:
            code.append(markdown)
        }
    }
    
    func finishDoc() {
        switch format {
        case .htmlFragment, .htmlDoc:
            code.append("</body>")
            code.append("</html>")
        case .markdown:
            let x = 0
        }
    }
}

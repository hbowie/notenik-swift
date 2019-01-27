//
//  Markedup.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Down
import Foundation

/// An object capable of generating marked up text (currently HTML or Markdown)
class Markedup: NSObject {
    
    var format : MarkedupFormat = .html
    var code = ""
    
    convenience init (format: MarkedupFormat) {
        self.init()
        self.format = format
    }
    
    /// Return the description, used as the String value for the object
    override var description: String {
        return code
    }
    
    func startDoc() {
        switch format {
        case .html:
            code.append("<html>")
            code.append("<head>")
            code.append("</head>")
            code.append("<body>")
        case .markdown:
            let x = 0
        }
    }
    
    func startParagraph() {
        switch format {
        case .html:
            code.append("<p>")
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        }
    }
    
    func startStrong() {
        switch format {
        case .html:
            code.append("<strong>")
        case .markdown:
            code.append("**")
        }
    }
    
    func finishStrong() {
        switch format {
        case .html:
            code.append("</strong>")
        case .markdown:
            code.append("**")
        }
    }
    
    func startEmphasis() {
        switch format {
        case .html:
            code.append("<em>")
        case .markdown:
            code.append("*")
        }
    }
    
    func finishEmphasis() {
        switch format {
        case .html:
            code.append("</em>")
        case .markdown:
            code.append("*")
        }
    }
    
    func link(text: String, path: String) {
        switch format {
        case .html:
            code.append("<a href=\"" + path + "\">" + text + "</a>")
        case .markdown:
            code.append("[" + text + "](" + path + ")")
        }
    }
    
    func codeBlock(_ block: String) {
        switch format {
        case .html:
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
        case .html:
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
        case.html:
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
        case .html:
            code.append("</body>")
            code.append("</html>")
        case .markdown:
            let x = 0
        }
    }
}

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
    
    var md = ""
    var html = ""
    var ok = true
    
    var parserID = "down"
    
    func parse() {
        ok = true
        html = ""
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
}

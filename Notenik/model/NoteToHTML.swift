//
//  NoteToHTML.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa
import Down

/// Generate the HTML necessary to display a Note in the form of a web page.
class NoteToHTML: NSObject {

    /// Get the HTML code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the HTML to be passed to a Web View.
    func getHTML(from note: Note) -> String {
        let collection = note.collection
        let dict = collection.dict
        var html = ""
        html.append("<html>")
        html.append("<head>")
        html.append("</head>")
        html.append("<body>")
        var i = 0
        if note.hasTags() {
            let tagsField = note.getField(label: LabelConstants.tags)
            html.append(getHTML(from: tagsField!))
        }
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if (field != nil &&
                    field!.value.hasData &&
                    field!.def.fieldLabel.commonForm != LabelConstants.tagsCommon) {
                    html.append(getHTML(from: field!))
                }
            }
            i += 1
        }
        html.append("</body>")
        html.append("</html>")
        return html
    }
    
    
    /// Get the HTML code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the HTML code that can be used to display this field.
    func getHTML(from field: NoteField) -> String {
        var html = ""
        
        if field.def.fieldLabel.commonForm == LabelConstants.titleCommon {
            html.append("<p><strong>")
            html.append(field.value.value)
            html.append("</strong></p>")
        } else if field.def.fieldLabel.commonForm == LabelConstants.tagsCommon {
            html.append("<p><em>")
            html.append(field.value.value)
            html.append("</em></p>")
        } else if field.def.fieldLabel.commonForm == LabelConstants.bodyCommon {
            html.append("<p>")
            html.append(field.def.fieldLabel.properForm)
            html.append(": ")
            html.append("</p>")
            html.append(getHTML(from: field.value.value))
        } else {
            html.append("<p>")
            html.append(field.def.fieldLabel.properForm)
            html.append(": ")
            html.append(field.value.value)
            html.append("</p>")
        }
        return html
    }
    
    /// Get the HTML code generated using the Markdown syntax.
    ///
    /// - Parameter markdown: A string containing text, including Markdown formatting.
    /// - Returns: The HTML generated from the Markdown text. 
    func getHTML(from markdown: String) -> String {
        let down = Down(markdownString: markdown)
        var html = ""
        do {
            html = try down.toHTML()
        } catch {
            print("Markdown parser through an error!")
        }
        return html
    }
}

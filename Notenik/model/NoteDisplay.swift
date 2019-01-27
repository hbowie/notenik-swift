//
//  NoteToHTML.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// Generate the coding necessary to display a Note in a pretty format.
class NoteDisplay: NSObject {
    
    var format: MarkedupFormat = .html

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    func display(_ note: Note) -> String {
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: format)
        code.startDoc()
        var i = 0
        if note.hasTags() {
            let tagsField = note.getField(label: LabelConstants.tags)
            code.append(display(tagsField!))
        }
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if (field != nil &&
                    field!.value.hasData &&
                    field!.def.fieldLabel.commonForm != LabelConstants.tagsCommon) {
                    code.append(display(field!))
                }
            }
            i += 1
        }
        code.finishDoc()
        return String(describing: code)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField) -> String {
        let code = Markedup(format: format)

        if field.def.fieldLabel.commonForm == LabelConstants.titleCommon {
            code.startParagraph()
            code.startStrong()
            code.append(field.value.value)
            code.finishStrong()
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == LabelConstants.tagsCommon {
            code.startParagraph()
            code.startEmphasis()
            code.append(field.value.value)
            code.finishEmphasis()
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == LabelConstants.bodyCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.append(markdown: field.value.value)
        } else if field.def.fieldLabel.commonForm == LabelConstants.linkCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.link(text: field.value.value, path: field.value.value)
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == LabelConstants.codeCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock(field.value.value)
        } else {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.append(field.value.value)
            code.finishParagraph()
        }

        return String(describing: code)
    }
    
}

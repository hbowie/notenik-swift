//
//  NoteDisplay.swift
//  Notenik
//
//  Created by Herb Bowie on 1/22/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Generate the coding necessary to display a Note in a readable format.
class NoteDisplay: NSObject {
    
    var format: MarkedupFormat = .htmlDoc
    
    let displayPrefs = DisplayPrefs.shared

    /// Get the code used to display this entire note as a web page, including html tags.
    ///
    /// - Parameter note: The note to be displayed.
    /// - Returns: A string containing the encoded note.
    func display(_ note: Note, io: NotenikIO) -> String {
        let collection = note.collection
        let dict = collection.dict
        let code = Markedup(format: format)
        code.notenikIO = io
        code.startDoc(withTitle: note.title.value, withCSS: displayPrefs.bodyCSS)
        var i = 0
        if note.hasTags() {
            let tagsField = note.getField(label: LabelConstants.tags)
            code.append(display(tagsField!, io: io))
        }
        while i < dict.count {
            let def = dict.getDef(i)
            if def != nil {
                let field = note.getField(def: def!)
                if (field != nil &&
                    field!.value.hasData &&
                    field!.def.fieldLabel.commonForm != LabelConstants.tagsCommon &&
                    field!.def.fieldLabel.commonForm != LabelConstants.dateAddedCommon &&
                    field!.def.fieldLabel.commonForm != LabelConstants.timestampCommon) {
                    code.append(display(field!, io: io))
                }
            }
            i += 1
        }
        if note.hasDateAdded() || note.hasTimestamp() {
            code.horizontalRule()
            let stamp = note.getField(label: LabelConstants.timestamp)
            if stamp != nil {
                code.append(display(stamp!, io: io))
            }
            let dateAdded = note.getField(label: LabelConstants.dateAdded)
            if dateAdded != nil {
                code.append(display(dateAdded!, io: io))
            }
        }
        code.finishDoc()
        return String(describing: code)
    }
    
    
    /// Get the code used to display this field
    ///
    /// - Parameter field: The field to be displayed.
    /// - Returns: A String containing the code that can be used to display this field.
    func display(_ field: NoteField, io: NotenikIO) -> String {
        let code = Markedup(format: format)
        code.notenikIO = io
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
            var pathDisplay = field.value.value.removingPercentEncoding
            if pathDisplay == nil {
                pathDisplay = field.value.value
            }
            code.link(text: pathDisplay!, path: field.value.value)
            code.finishParagraph()
        } else if field.def.fieldLabel.commonForm == LabelConstants.codeCommon {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.codeBlock(field.value.value)
        } else if field.def.fieldType.typeString == "longtext" {
            code.startParagraph()
            code.append(field.def.fieldLabel.properForm)
            code.append(": ")
            code.finishParagraph()
            code.append(markdown: field.value.value)
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

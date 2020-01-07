//
//  AttachmentName.swift
//  Notenik
//
//  Created by Herb Bowie on 7/22/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The full name assigned to a Note attachment.
class AttachmentName: Comparable, NSCopying, CustomStringConvertible {
    
    let preferredSeparator = " | "
    
    var prefix = ""
    var separator = " | "
    var suffix = ""
    var ext = ""
    
    /// Standard string representation to conform to CustomStringConvertible.
    var description: String {
        return fullName
    }
    
    /// The full name for the attachment, consisting of
    /// prefix, separator, suffix and file extension.
    var fullName: String {
        return prefix + separator + suffix + ext
    }
    
    /// Is the first attachment name less than the second?
    static func < (lhs: AttachmentName, rhs: AttachmentName) -> Bool {
        return lhs.fullName < rhs.fullName
    }
    
    /// Are the two attachment names equal?
    static func == (lhs: AttachmentName, rhs: AttachmentName) -> Bool {
        return lhs.fullName == rhs.fullName
    }
    
    /// Make a copy of this Attachment Name. 
    func copy(with zone: NSZone? = nil) -> Any {
        let newAttachmentName = AttachmentName()
        newAttachmentName.prefix = self.prefix
        newAttachmentName.separator = self.separator
        newAttachmentName.suffix = self.suffix
        newAttachmentName.ext = self.ext
        return newAttachmentName
    }
    
    /// Given a Note and the full file name for an attachment,
    /// separate out the name into its constituent parts.
    func setName(note: Note, fullName: String) {
        prefix = ""
        separator = ""
        suffix = ""
        ext = ""
        guard let fnBase = note.fileInfo.base else { return }
        prefix = fnBase
        var index = fullName.index(fullName.startIndex, offsetBy: prefix.count)
        while index < fullName.endIndex {
            let char = fullName[index]
            if suffix.count == 0 && (char.isWhitespace || char.isPunctuation) {
                separator.append(char)
            } else if char == "." {
                if ext.count > 0 {
                    suffix.append(ext)
                    ext = ""
                }
                ext.append(char)
            } else if ext.count > 0 {
                ext.append(char)
            } else {
                suffix.append(char)
            }
            index = fullName.index(after: index)
        }
    }
    
    /// Set the various components of the Attachment Name.
    ///
    /// - Parameters:
    ///   - fromFile: The URL of the file to be attached, which supplies the file extension.
    ///   - note: The note to which the file is to be attached, which supplies the prefix.
    ///   - suffix: The suffix to be used.
    func setName(fromFile: URL, note: Note, suffix: String) {
        self.prefix = ""
        self.separator = ""
        self.suffix = ""
        self.ext = ""
        guard let fnBase = note.fileInfo.base else { return }
        let fromFileName = FileName(fromFile)
        self.prefix = fnBase
        self.separator = preferredSeparator
        self.suffix = suffix
        self.ext = "." + fromFileName.ext
    }
    
    /// Change the prefix based on the passed note, but leave
    /// other elements of the attachment name as-is. 
    func changeNote(note: Note) {
        guard let fnBase = note.fileInfo.base else { return }
        self.prefix = fnBase
    }
}

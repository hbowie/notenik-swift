//
//  NoteFileFormat.swift
//  Notenik
//
//  Created by Herb Bowie on 12/31/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

/// An indicator of the format used to store the note on disk.
enum NoteFileFormat: String {
    
    /// In Markdown format, the first line of the file contains a level 1 heading, and this
    /// is used as the Note's title. The rest of the file makes up the Note's body.
    case markdown       = "md"
    
    /// In MultiMarkdown format, the file may start with metadata, and the first blank line
    /// separates the metadata from the body.
    case multiMarkdown  = "mmd"
    
    /// In Notenik format, blank lines may separate metadata lines, and the
    /// body is explicitly identified with a Body label.
    case notenik        = "nnk"
    
    /// Indicates that the file format is yet to be determined.
    case toBeDetermined = "tbd"
    
    /// The first line of the file contains neither a Title label nor
    /// a Markdown level 1 heading. The title is taken from the
    /// file name (minus the extension) and the entire file
    /// contents make up the body. 
    case plainText      = "txt"
}

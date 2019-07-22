//
//  AttachmentMasterController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/21/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A controller capable of adding an attachment, given a suffix. 
protocol AttachmentMasterController {
    

    /// The user has responded OK to proceed with adding an attachment.
    ///
    /// - Parameters:
    ///   - note: The note to which the attachment should be added.
    ///   - file: A URL pointing to the file to become attached.
    ///   - suffix: The unique identifier for this particular attachment to this note.
    ///
    func okToAddAttachment(note: Note, file: URL, suffix: String)
}

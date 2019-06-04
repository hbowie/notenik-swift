//
//  Template.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A template to be used to create text file output
/// (such as an HTML file) from a Collection of Notes.
class Template {
    
    var templateUtil = TemplateUtil()
    
    init() {
        
    }
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors.
    func openTemplate(templateURL: URL) -> Bool {
        return templateUtil.openTemplate(templateURL: templateURL)
    }
}

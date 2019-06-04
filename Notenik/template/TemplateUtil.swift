//
//  TemplateUtil.swift
//  Notenik
//
//  Created by Herb Bowie on 6/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Persistent data used by Template Lines. 
class TemplateUtil {
    
    var templateURL: URL?
    var lineReader:  LineReader?
    
    
    /// Open a new template file.
    ///
    /// - Parameter templateURL: The location of the template file.
    /// - Returns: True if opened ok, false if errors. 
    func openTemplate(templateURL: URL) -> Bool {
        self.templateURL = templateURL
        do {
            let templateContents = try String(contentsOf: templateURL, encoding: .utf8)
            lineReader = BigStringReader(templateContents)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "TemplateUtil",
                              level: .error,
                              message: "Error reading Template from \(templateURL)")
            return false
        }
        return true
    }
    
}

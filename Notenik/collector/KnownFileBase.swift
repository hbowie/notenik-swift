//
//  KnownFileBase.swift
//  Notenik
//
//  Created by Herb Bowie on 4/23/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The base upon which more detailed paths can be built. 
class KnownFileBase {
    var name = ""
    var url: URL
    
    init() {
        name = "root"
        url = URL(fileURLWithPath: "/")
    }
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    /// Path.
    var path: String {
        return url.path
    }
    
    /// Number of path components.
    var count: Int {
        return url.pathComponents.count
    }
}

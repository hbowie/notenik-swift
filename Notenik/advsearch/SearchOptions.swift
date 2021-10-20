//
//  SearchOptions.swift
//  Notenik
//
//  Created by Herb Bowie on 10/19/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class SearchOptions {

    var searchText = ""
    
    var titleField = true
    var akaField = true
    var linkField = true
    var tagsField = true
    var authorField = true
    var bodyField = true
    
    var caseSensitive = false
    
    init() {
        
    }
}

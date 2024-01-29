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

    var _searchText = ""
    var searchText: String {
        get {
            return _searchText
        }
        set {
            hashTag = newValue.starts(with: "#")
            if hashTag {
                _searchText = String(newValue.dropFirst(1))
            } else {
                _searchText = newValue
            }
        }
    }
    
    var titleField = true
    var akaField = true
    var linkField = true
    var tagsField = true
    var authorField = true
    var bodyField = true
    
    var caseSensitive = false
    
    var scope: SearchScope {
        get {
            return _scope
        }
        set {
            _scope = newValue
            anchorSeq = ""
            anchorSortKey = ""
        }
    }
    var _scope: SearchScope = .all
    
    var anchorSortKey = ""
    var anchorSeq = ""
    
    var hashTag = false
    
    init() {
        
    }
    
    enum SearchScope {
        case all
        case within
        case forward
    }
    
}

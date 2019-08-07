//
//  IndexCollection.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class IndexCollection {
    
    var dict: [String:IndexTerm] = [:]
    var list: [IndexTerm] = []
    
    var position: IndexPosition = .term
    var parenDepth = 0
    var term = ""
    var link = ""
    var anchor = ""
    var pendingSpaces = 0


    func clear() {
        dict = [:]
        list = []
    }
    
    func containsKey(key: String) -> Bool {
        let term = dict[key]
        return term != nil
    }
    
    func add(page: String, index: IndexValue) {
        clearTermVars()
        for c in index.value {
            switch c {
            case "(":
                if parenDepth == 0 {
                    position = .link
                } else {
                    append(c)
                }
                parenDepth += 1
            case ")":
                parenDepth -= 1
                if parenDepth == 0 {
                    position = .term
                } else {
                    append(c)
                }
            case "#":
                position = .anchor
            case ";":
                endOfTermEntry(page: page)
            case " ":
                pendingSpaces += 1
            default:
                if pendingSpaces > 0 && charCount > 0 {
                    while pendingSpaces > 0 {
                        append(" ")
                        pendingSpaces -= 1
                    }
                }
                append(c)
                pendingSpaces = 0
            }
        }
        endOfTermEntry(page: page)
    }
    
    func append(_ c: Character) {
        switch position {
        case .term:
            term.append(c)
        case .link:
            link.append(c)
        case .anchor:
            anchor.append(c)
        }
    }
    
    var charCount: Int {
        switch position {
        case .term:
            return term.count
        case .link:
            return link.count
        case .anchor:
            return anchor.count
        }
    }
    
    func endOfTermEntry(page: String) {
        if term.count > 0 {
            var indexTerm = dict[term]
            if indexTerm == nil {
                indexTerm = IndexTerm(term: term)
                dict[term] = indexTerm!
                list.append(indexTerm!)
            }
            if link.count > 0 {
                indexTerm!.link = link
            }
            let ref = IndexPageRef(term: indexTerm!, page: page, anchor: anchor)
            indexTerm!.addRef(ref)
        }
        clearTermVars()
    }
    
    func clearTermVars() {
        position = .term
        parenDepth = 0
        term = ""
        link = ""
        anchor = ""
        pendingSpaces = 0
    }
    
    enum IndexPosition {
        case term
        case link
        case anchor
    }
}

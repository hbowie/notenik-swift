//
//  IndexTerm.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class IndexTerm {
    var term = ""
    var link = ""
    var refs: [IndexPageRef] = []
    
    init() {
        
    }
    
    init(term: String) {
        self.term = term
    }
    
    var key: String {
        return term.lowercased() + term
    }
    
    func addRef(_ ref: IndexPageRef) {
        var i = 0
        var looking = true
        while i < refs.count && looking {
            let nextRef = refs[i]
            if ref.key <= nextRef.key {
                refs.insert(ref, at: i)
                looking = false
            } else {
                i += 1
            }
        }
        if looking {
            refs.append(ref)
        }
    }
}

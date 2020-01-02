//
//  Realm.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class Realm {
    
    var provider: Provider = Provider()
    var name = ""
    var path = ""
    var io: NotenikIO?
    
    init() {
        
    }
    
    convenience init (provider: Provider) {
        self.init()
        self.provider = provider
    }
    
    convenience init (provider: Provider, name: String, path: String) {
        self.init()
        
        self.provider = provider
        self.name = name
        self.path = path
        
    }
    
}

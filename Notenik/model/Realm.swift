//
//  Realm.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

class Realm {
    
    var provider : Provider = Provider()
    var name = ""
    var path = ""
    
    init() {
        
    }
    
    convenience init (provider : Provider) {
        self.init()
        self.provider = provider
    }
    
    convenience init (provider : Provider, name : String, path : String) {
        self.init()
        
        self.provider = provider
        self.name = name
        self.path = path
        
    }
    
}

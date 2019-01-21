//
//  Provider.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A Provider provides the operating and storage context for one or more users, and one or more realms.
class Provider {
    
    var providerType : ProviderType = .file
    
    init() {
        
    }
    
    convenience init (_ type : ProviderType) {
        self.init()
        self.providerType = type
    }
    
}

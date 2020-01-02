//
//  Provider.swift
//  Notenik
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Provider provides the operating and storage context for one or more users, and one or more realms.
class Provider {
    
    var providerType: ProviderType = .file
    
    init() {
        
    }
    
    convenience init (_ type: ProviderType) {
        self.init()
        self.providerType = type
    }
    
}

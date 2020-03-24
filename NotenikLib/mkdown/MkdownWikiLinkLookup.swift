//
//  MkdownLinkLookup.swift
//  Notenik
//
//  Created by Herb Bowie on 3/22/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A protocol for looking up a title and transforming it to a different value.
protocol MkdownWikiLinkLookup {
    
    func mkdownWikiLinkLookup(title: String) -> String
    
}

//
//  DefsRemoved.swift
//  Notenik
//
//  Created by Herb Bowie on 11/1/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation
import NotenikLib

public class DefsRemoved {
    
    public var list: [FieldDefinition] = []
    public var count: Int { return list.count }
    
    public init() {
        
    }
    
    public func clear() {
        list = []
    }
    
    public func append(_ def: FieldDefinition) {
        list.append(def)
    }
}

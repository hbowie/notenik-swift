//
//  NotePosition.swift
//  Notenik
//
//  Created by Herb Bowie on 12/29/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// An object that defines a particular Note's position within the sorted list
/// containing all Notes in the Collection. 
class NotePosition {
    
    var index = 0
    
    /// Default initializer with index = 0.
    init() {
        
    }
    
    /// Convenience initializer with an index value.
    convenience init(index : Int) {
        self.init()
        self.index = index
    }
}

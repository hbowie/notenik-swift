//
//  CollectionPrefsOwner.swift
//  Notenik
//
//  Created by Herb Bowie on 4/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A protocol to be implemented by the caller of the CollectionPrefsWindowController. 
protocol CollectionPrefsOwner {
    
    /// Let the calling class know that the user has completed modifications
    /// of the Collection Preferences.
    func collectionPrefsModified(ok: Bool,
                                 collection: NoteCollection,
                                 window: CollectionPrefsWindowController)
    
}

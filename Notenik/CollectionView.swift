//
//  CollectionView.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/24.
//  Copyright © 2024 PowerSurge Publishing. All rights reserved.
//

import Foundation

import NotenikLib

protocol CollectionView {
    
    var viewID: String { get set }
    
    var coordinator: CollectionViewCoordinator? { get set }
    
    func setCoordinator(coordinator: CollectionViewCoordinator) 
    
    /// Focus on the specified Note, by specifying either the Note itself or its position in the list.
    /// - Parameters:
    ///   - note: The note to be selected.
    ///   - position: The position of the selection.
    ///   - searchPhrase: Any search phrase currently in effect. 
    func focusOn(initViewID: String,
                 note: Note?,
                 position: NotePosition?,
                 io: NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool)
}

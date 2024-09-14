//
//  CollectionViewsCoordinator.swift
//  Notenik
//
//  Created by Herb Bowie on 8/7/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

/// This class coordinated the selection of a note between the various views.
class CollectionViewCoordinator: NSObject {
    
    var collectionWindowController: CollectionWindowController
    
    var lastNote: Note?
    var lastViewID = ""
    
    var scroller: NoteScroller?
    
    var navHistory: NavHistory!

    var views: [CollectionView] = []
    
    var focusPending = false
    
    init(collectionWindowController: CollectionWindowController) {
        self.collectionWindowController = collectionWindowController
    }
    
    var notenikIO: NotenikIO? {
        get {
            return _io
        }
        set {
            _io = newValue
            if newValue != nil {
                navHistory = NavHistory(io: newValue!)
            }
            lastNote = nil
            lastViewID = ""
        }
    }
    var _io: NotenikIO?
    
    func addView(newView: CollectionView) {
        newView.setCoordinator(coordinator: self)
        var i = 0
        var found = false
        while i < views.count && !found {
            if newView.viewID == views[i].viewID {
                found = true
                views[i] = newView
            } else {
                i += 1
            }
        }
        if !found {
            views.append(newView)
        }
        if notenikIO != nil && lastNote != nil && !lastViewID.isEmpty {
            newView.focusOn(initViewID: lastViewID,
                            note: lastNote,
                            position: nil,
                            io: notenikIO!,
                            searchPhrase: nil,
                            withUpdates: false)
        }
    }
    
    func removeView(viewID: String) {
        var i = 0
        var found = false
        while i < views.count && !found {
            if viewID == views[i].viewID {
                found = true
                views.remove(at: i)
            } else {
                i += 1
            }
        }
    }
    
    /// Focus on the specified Note, by specifying either the Note itself or its position in the list.
    /// - Parameters:
    ///   - initViewID: Identifier for the initiating view.
    ///   - note: The note to be selected.
    ///   - position: The position of the selection.
    ///   - row: The row index in the list, or -1 if not available.
    ///   - searchPhrase: Any search phrase currently in effect.
    ///
    /// - Returns: True if all went well, false if focus was not able to be completed.
    func focusOn(initViewID: String,
                 note: Note?,
                 position: NotePosition?,
                 row: Int,
                 searchPhrase: String?,
                 withUpdates: Bool = false) -> Bool {
        
        guard !focusPending else {
            return false
        }
        guard notenikIO != nil && notenikIO!.collectionOpen else { return false }
        
        focusPending = true
        let (outcome, _) = collectionWindowController.modIfChanged()
        guard outcome != modIfChangedOutcome.tryAgain else {
            focusPending = false
            return false
        }
        
        collectionWindowController.applyCheckBoxUpdates()
        
        scroller = NoteScroller(collection: notenikIO!.collection!)
        
        var noteToUse: Note? = note
        var positionToUse: NotePosition? = position
        
        if note == nil && row >= 0 {
            noteToUse = notenikIO!.getNote(at: row)
        }
        
        if noteToUse != nil && (position == nil || position!.invalid) {
            positionToUse = notenikIO!.positionOfNote(noteToUse!)
        }
        
        if noteToUse == nil && position != nil && position!.valid {
            noteToUse = notenikIO!.getNote(at: position!.index)
        }
        
        guard noteToUse != nil else {
            focusPending = false
            return false
        }
        
        /*
        if listVC != nil && source != .list && positionToUse != nil && positionToUse!.index >= 0 {
            listVC!.selectRow(index: positionToUse!.index, andScroll: andScroll, checkForMods: (source != .action))
        }
        guard noteToUse != nil else { return }
        
        if displayVC != nil {
            displayVC!.display(note: noteToUse!, io: notenikIO!, searchPhrase: searchPhrase)
        }
        if editVC != nil {
            editVC!.select(note: noteToUse!)
        } */
        collectionWindowController.adjustAttachmentsMenu(noteToUse!)
        
        navHistory!.addToHistory(another: noteToUse!)
        
        focusPending = true
        
        for view in views {
            view.focusOn(initViewID: initViewID,
                         note: noteToUse,
                         position: positionToUse,
                         io: notenikIO!,
                         searchPhrase: searchPhrase,
                         withUpdates: withUpdates)
        }
        
        lastNote = noteToUse
        lastViewID = initViewID
        
        focusPending = false
        
        return true
    }
    
}

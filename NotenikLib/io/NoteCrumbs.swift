//
//  NoteCrumbs.swift
//  Notenik
//
//  Created by Herb Bowie on 12/12/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Keep track of where we've been and how we got here, and allow the user
/// to move forward and backwards in the list of notes s/he's visited.
class NoteCrumbs {
    
    var io: NotenikIO
    var crumbs: [String] = []
    var lastCrumb: String?
    
    init(io: NotenikIO) {
        self.io = io
    }
    
    /// Let's start over. 
    func refresh() {
        crumbs = []
    }
    
    /// Indicate the latest note visited by the user.
    func select(latest: Note) {
        let latestID = latest.noteID
        
        /// If this note is just the last one returned from this list, then don't
        /// disturb the current order.
        if latestID == lastCrumb { return }
        
        var index = 0
        for crumb in crumbs {
            if latestID == crumb {
                crumbs.remove(at: index)
                break
            }
            index += 1
        }
        crumbs.append(latestID)
    }
    
    /// Go back to the prior note in the breadcrumbs.
    /// - Parameter from: The Note we're starting from.
    func backup(from: Note) -> Note {
        let fromID = from.noteID
        var index = crumbs.count - 1
        while index > 0 {
            let crumb = crumbs[index]
            if fromID == crumb {
                let priorCrumb = crumbs[index - 1]
                let priorNote = io.getNote(forID: priorCrumb)
                if priorNote != nil {
                    lastCrumb = priorNote!.noteID
                    return priorNote!
                }
            }
            index -= 1
        }
        let position = io.positionOfNote(from)
        var (priorNote, _) = io.priorNote(position)
        if priorNote == nil {
            (priorNote, _) = io.lastNote()
        }
        lastCrumb = priorNote!.noteID
        return priorNote!
    }
    
    /// Go forward to the next Note in the list.
    /// - Parameter from: The Note we're starting from.
    func advance(from: Note) -> Note {
        let fromID = from.noteID
        var index = crumbs.count - 2
        while index >= 0 {
            let crumb = crumbs[index]
            if fromID == crumb {
                let nextCrumb = crumbs[index + 1]
                let nextNote = io.getNote(forID: nextCrumb)
                if nextNote != nil {
                    lastCrumb = nextNote!.noteID
                    return nextNote!
                }
            }
            index -= 1
        }
        let position = io.positionOfNote(from)
        var (nextNote, _) = io.nextNote(position)
        if nextNote == nil {
            (nextNote, _) = io.firstNote()
        }
        lastCrumb = nextNote!.noteID
        return nextNote!
    }
}

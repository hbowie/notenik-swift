//
//  Sequencer.swift
//  Notenik
//
//  Created by Herb Bowie on 9/20/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Can be used to increment the sequence of one Note and following Notes.
class Sequencer {
    
    /// Increment the sequence of one Note along with following Notes
    /// that would otherwise now be less than or equal to the
    /// sequences of prior Notes.
    ///
    /// - Parameters:
    ///   - io: The I/O Module for the Collection being accessed.
    ///   - startingNote: The first Note whose sequence is to be incremented.
    /// - Returns: The number of Notes having their sequences incremented.
    static func incrementSeq(io: NotenikIO, startingNote: Note) -> Int {
        
        guard io.collectionOpen else { return 0 }
        guard io.collection != nil else { return 0 }
        let sortParm = io.collection!.sortParm
        guard sortParm == .seqPlusTitle || sortParm == .tasksBySeq else { return 0 }
        guard startingNote.hasSeq() else { return 0 }
        
        var newSeqs: [SeqValue] = []
        var notes:   [Note] = []
        
        var incrementing = true
        var incrementingOnLeft = true
        var position = io.positionOfNote(startingNote)
        var note: Note? = startingNote
        var (nextNote, nextPosition) = io.nextNote(position)
        var starting = true
        var lastSeq: SeqValue?
        while incrementing && note != nil && position.valid {
            let seq = note!.seq
            
            // Special logic for first note processed
            if starting {
                lastSeq = SeqValue(seq.value)
                if seq.positionsToRightOfDecimal > 0 {
                    incrementingOnLeft = false
                }
                starting = false
            }
            
            // See if the current sequence is already greater than the last one
            var greater = (seq > lastSeq!)
            if greater {
                if incrementingOnLeft {
                    greater = (seq.left > lastSeq!.left)
                }
            }
            
            // See if we're done, or need to keep going
            if greater {
                incrementing = false
            } else {
                incrementing = true
                let newSeq = SeqValue(seq.value)
                newSeq.increment(onLeft: incrementingOnLeft)
                newSeqs.append(newSeq)
                notes.append(note!)
                lastSeq = SeqValue(newSeq.value)
            }
            
            starting = false
            
            note = nextNote
            position = nextPosition
            (nextNote, nextPosition) = io.nextNote(position)
        }
        
        // Now apply the new sequences from the top down, in order to
        // keep notes from changing position in the sorted list.
        var index = newSeqs.count - 1
        while index >= 0 {
            let newSeq = newSeqs[index]
            let noteToMod = notes[index]
            let setOK = noteToMod.setSeq(newSeq.value)
            let writeOK = io.writeNote(noteToMod)
            if (!setOK) || (!writeOK) {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "Sequencer",
                                  level: .error,
                                  message: "Trouble updating Note titled \(noteToMod.title.value)")
            }
            index -= 1
        }
        
        return newSeqs.count
    }
}

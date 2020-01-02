//
//  NoteSortParm.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

enum NoteSortParm : Int {
    case title        = 0
    case seqPlusTitle = 1
    case tasksByDate  = 2
    case tasksBySeq   = 3
    case author       = 4
    case custom       = 5
    
    // Get or set with a String containing the raw value
    var str: String {
        get {
            return String(self.rawValue)
        }
        set {
            if newValue.count > 0 {
                let sortParmInt = Int(newValue)
                if sortParmInt != nil {
                    let sortParmRaw = sortParmInt!
                    let sortParmWork: NoteSortParm? = NoteSortParm(rawValue: sortParmRaw)
                    if sortParmWork != nil {
                        self = sortParmWork!
                    }
                }
            }
        }
    }
}

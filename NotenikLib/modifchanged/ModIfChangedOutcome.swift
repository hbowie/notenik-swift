//
//  ModIfChangedOutcome.swift
//  Notenik
//
//  Created by Herb Bowie on 4/3/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Define the possible outcomes from the modIfChanged method
enum modIfChangedOutcome {
    case notReady
    case noChange
    case idAlreadyExists
    case tryAgain
    case discard
    case add
    case deleteAndAdd
    case modify
}

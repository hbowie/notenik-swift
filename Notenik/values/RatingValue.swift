//
//  RatingValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/8/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A value that can store a rating on a scale of 0 - 9
class RatingValue : StringValue {
    
    /// Return a number
    func getDouble() -> Double {
        let possibleDouble = Double(value)
        if possibleDouble != nil {
            return possibleDouble!
        } else {
            var possibleInt = Int(value)
            if possibleInt == nil {
                possibleInt = value.count
            }
            return Double(possibleInt!)
        }
    }
}

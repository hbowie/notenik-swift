//
//  TemplateComparisonOperator.swift
//  Notenik
//
//  Created by Herb Bowie on 6/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Comparison Operator used within a Template Command
class TemplateComparisonOperator {

    var op: ComparisonOperator = .undefined
    
    /// Initialize with a string contaning symbols, words or an abbreviation.
    convenience init(_ str: String) {
        self.init()
        switch str {
        case "=", "==", "eq", "equals":
            op = .equals
        case ">", "gt", "greater than":
            op = .greaterThan
        case ">=", "!<", "ge", "greater than or equal to":
            op = .greaterThanOrEqualTo
        case "<", "lt", "less than":
            op = .lessThan
        case "<=", "!>", "le", "less than or equal to":
            op = .lessThanOrEqualTo
        case "<>", "!=", "ne", "not equal to":
            op = .notEqualTo
        case "()", "[]", "co", "contains":
            op = .contains
        case "!()", "![]", "nc", "does not contain":
            op = .doesNotContaIn
        case "(<)", "[<]", "st", "starts with":
            op = .startsWith
        case "!(<)", "![<]", "ns", "does not start with":
            op = .doesNotStartWith
        case "(>)", "[>]", "fi", "ends with":
            op = .endsWith
        case "!(>)", "![>]", "nf", "does not end with":
            op = .doesNotEndWith
        default:
            op = .undefined
        }
    }
    
    /// Perform the appropriate comparison using the two passed vaLues.
    func compare(_ value1: String, _ value2: String) -> Bool {
        
        let int1 = Int(value1)
        let int2 = Int(value2)
        if validForInts && int1 != nil && int2 != nil {
            return compareInts(int1!, int2!)
        }
        
        // Compare the string values.
        switch op {
        case .equals:
            return value1 == value2
        case .notEqualTo:
            return value1 != value2
        case .greaterThan:
            return value1 > value2
        case .greaterThanOrEqualTo:
            return value1 >= value2
        case .lessThan:
            return value1 < value2
        case .lessThanOrEqualTo:
            return value1 <= value2
        case .contains:
            return value1.contains(value2)
        case .doesNotContaIn:
            return !(value1.contains(value2))
        case .startsWith:
            return value1.hasPrefix(value2)
        case .doesNotStartWith:
            return !(value1.hasPrefix(value2))
        case .endsWith:
            return value1.hasSuffix(value2)
        case .doesNotEndWith:
            return !(value1.hasSuffix(value2))
        default:
            return true
        }
        
    }
    
    /// Is this operator valid for integers?
    var validForInts: Bool {
        switch op {
        case .equals, .greaterThanOrEqualTo, .greaterThan, .notEqualTo, .lessThanOrEqualTo, .lessThan:
            return true
        default:
            return false
        }
    }
    
    /// Compare integer values
    func compareInts(_ int1: Int, _ int2: Int) -> Bool {
        switch op {
        case .equals:
            return int1 == int2
        case .notEqualTo:
            return int1 != int2
        case .greaterThan:
            return int1 > int2
        case .greaterThanOrEqualTo:
            return int1 >= int2
        case .lessThan:
            return int1 < int2
        case .lessThanOrEqualTo:
            return int1 <= int2
        default:
            return true
        }
    }
}

/// The enum used to identify the comparison operator.
enum ComparisonOperator {
    
    case undefined
    case equals
    case greaterThan
    case greaterThanOrEqualTo
    case lessThan
    case lessThanOrEqualTo
    case notEqualTo
    case contains
    case doesNotContaIn
    case startsWith
    case doesNotStartWith
    case endsWith
    case doesNotEndWith
}

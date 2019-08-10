//
//  RecursValue.swift
//  Notenik
//
//  Created by Herb Bowie on 11/29/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class RecursValue : StringValue {
    
    var interval     = 0
    let intervalHalf = -1
    
    var unit = 0
    let unitNone     = 0
    let unitDays     = 1
    let unitWeeks    = 2
    let unitMonths   = 3
    let unitQuarters = 4
    let unitYears    = 5
    
    var weekdays = false
    var dayOfWeek = 0
    var dayOfMonth = 0
    var weekOfMonth = 0
    var sequence = 0
    
    override init() {
        super.init()
    }
    
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Recurs every day?
    var daily: Bool {
        return unit == unitDays && interval == 1
    }
    
    /**
     Increment a date using this recurs rule.
     */
    func recur(_ strDate: DateValue) -> String {
        let possibleDate = strDate.date
        let newDate = SimpleDate(dateValue: strDate)
        if possibleDate == nil {
            return String(describing: strDate)
        } else {
            var bumped = false
            switch unit {
            case unitDays:
                newDate.addDays(interval)
                bumped = true
                if weekdays {
                    while newDate.weekend {
                        newDate.addDays(1)
                    }
                }
            case unitWeeks:
                newDate.addDays(interval * 7)
                bumped = true
            case unitMonths:
                newDate.addMonths(interval)
                bumped = true
            case unitQuarters:
                newDate.addMonths(interval * 3)
                bumped = true
            case unitYears:
                newDate.addYears(interval)
                bumped = true
            default:
                break
            }
            if !(bumped) {
                newDate.addDays(1)
            }
            if dayOfMonth > 0 {
                newDate.setDayOfMonth(dayOfMonth)
            }
            if dayOfWeek > 0 {
                while newDate.dayOfWeek != dayOfWeek {
                    newDate.addDays(1)
                }
            }
            if strDate.alphaMonth {
                return DateUtils.shared.dMyFromDate(newDate.date!)
            } else {
                return DateUtils.shared.ymdFromDate(newDate.date!)
            }
        } // end if we have a real date to increment
    } // end func recur
    
    /**
     Set the date's value to a new string, parsing the input and attempting to
     identify the year, month and date
     */
    override func set(_ value: String) {
        
        super.set(value)
        
        interval = 0
        unit = -1
        weekdays = false
        dayOfWeek = 0
        dayOfMonth = 0
        weekOfMonth = 0
        sequence = 0
        
        var word = RecursWord()
        word.precedingSeps = 1
        
        for c in value {
            if StringUtils.isDigit(c) {
                if word.letters > 0 {
                    processWord(word: word)
                    word = RecursWord()
                }
                word.digits += 1
                word.append(c)
            } else if StringUtils.isAlpha(c) {
                if word.digits > 0 {
                    processWord(word: word)
                    word = RecursWord()
                }
                word.letters += 1
                word.append(c)
            } else {
                // Neither alpha nor numeric -- must be whitespace or punctuation
                if word.hasData {
                    processWord(word: word)
                    word = RecursWord()
                }
                word.precedingSeps += 1
            } // end if c is some miscellaneous punctuation
            if word.lowercased() == "every" ||
                word.lowercased() == "semi" ||
                word.lowercased() == "bi" {
                processWord(word: word)
                word = RecursWord()
            }
        } // end for c in value
        if word.hasData {
            processWord(word: word)
        }
        if unit > unitNone && interval == 0 {
            interval = 1
        }
    }
    
    /**
     Process each parsed word once it's been completed.
     */
    func processWord(word: RecursWord) {
        word.complete()
        if word.numberWord {
            processNumber(word: word)
        } else if word.alphaWord {
            processAlpha(word: word)
        }
    }
    
    /// Perform appropriate processing for something other than a number
    func processAlpha(word: RecursWord) {
        if word.precedingSeps == 0 &&
            (word.lower == "nd" || word.lower == "th" || word.lower == "st" || word.lower == "rd") {
            return
        }
        switch word.lower {
        case "of":
            sequence = interval
            interval = 1
        case "every":
            break
        case "day", "days", "daily":
            unit = unitDays
        case "weekday", "weekdays":
            unit = unitDays
            weekdays = true
        case "week", "weeks", "weekly":
            unit = unitWeeks
        case "month", "months", "monthly":
            unit = unitMonths
            if sequence > 0 {
                dayOfMonth = sequence
                sequence = 0
            }
        case "quarter", "quarters", "quarterly":
            unit = unitQuarters
        case "year", "years", "annual", "annually", "yearly":
            unit = unitYears
        default:
            let possibleDayOfWeek = DateUtils.shared.matchDayOfWeekName(word.lowercased())
            if possibleDayOfWeek > 0 {
                dayOfWeek = possibleDayOfWeek
                if unit <= unitNone {
                    unit = unitWeeks
                }
            }
        }
    }
    
    func processNumber(word: RecursWord) {
        interval = word.number
    }
    
    func display() {
        print("  - unit          = \(unit)")
        print("  - interval      = \(interval)")
        print("  - weekdays?       \(weekdays)")
        print("  - day of week   = \(dayOfWeek)")
        print("  - day of month  = \(dayOfMonth)")
        print("  - week of month = \(weekOfMonth)")
        print("  - sequence      = \(sequence)")
    }
    
    /// One word parsed from the recurs value
    class RecursWord {
        
        var word = ""
        var lower = ""
        var number = 0
        
        var digits = 0
        var letters = 0
        var precedingSeps = 0
        
        var alphaWord = false
        var numberWord = false
        
        init() {
            
        }
        
        func append(_ c: Character) {
            word.append(c)
        }
        
        var isEmpty : Bool {
            return (word.count == 0)
        }
        
        var hasData : Bool {
            return (word.count > 0)
        }
        
        var count: Int {
            return word.count
        }
        
        func lowercased() -> String {
            if word.count > 0 && lower.count == 0 {
                lower = word.lowercased()
            }
            return lower
        }
        
        /// Complete word settings once we have an entire word
        func complete() {
            lower = word.lowercased()
            number = 0
            if digits > 0 {
                let possibleNumber : Int? = Int(word)
                if possibleNumber != nil {
                    number = possibleNumber!
                }
            } else if letters > 0 {
                switch lower {
                case "first", "one":
                    number = 1
                case "second", "two", "other":
                    number = 2
                case "third", "three":
                    number = 3
                case "fourth", "four":
                    number = 4
                case "fifth", "five":
                    number = 5
                case "sixth", "six":
                    number = 6
                case "seventh", "seven":
                    number = 7
                default:
                    break
                }
            }
            if number > 0 {
                numberWord = true
            } else if letters > 0 {
                alphaWord = true
            }
        }
    } // end inner class RecursWord
} // end class RecursValue

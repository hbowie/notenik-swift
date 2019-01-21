//
//  RecursValue.swift
//  Notenik
//
//  Created by Herb Bowie on 11/29/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
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
    
    /**
     Increment a date using this recurs rule.
     */
    func recur(_ strDate : DateValue) -> String {
        let possibleDate = strDate.date
        var newDate = Date()
        if possibleDate == nil {
            return String(describing: strDate)
        } else {
            let date = possibleDate!
            var bumped = false
            var dateComponent = DateComponents()
            var oneDay = DateComponents()
            oneDay.day = 1
            switch unit {
            case unitDays:
                dateComponent.day = interval
                newDate = Calendar.current.date(byAdding: dateComponent, to: date)!
                bumped = true
                if weekdays {
                    var dow = DateUtils.shared.dayOfWeekForDate(newDate)
                    while dow == DateUtils.saturday || dow == DateUtils.sunday {
                        newDate = Calendar.current.date(byAdding: oneDay, to: newDate)!
                        dow = DateUtils.shared.dayOfWeekForDate(newDate)
                    }
                }
            case unitWeeks:
                dateComponent.day = interval * 7
                newDate = Calendar.current.date(byAdding: dateComponent, to: date)!
                bumped = true
            case unitMonths:
                dateComponent.month = interval
                newDate = Calendar.current.date(byAdding: dateComponent, to: date)!
                bumped = true
            case unitQuarters:
                dateComponent.month = interval * 3
                newDate = Calendar.current.date(byAdding: dateComponent, to: date)!
                bumped = true
            case unitYears:
                dateComponent.year = interval
                newDate = Calendar.current.date(byAdding: dateComponent, to: date)!
                bumped = true
            default:
                break
            }
            if !(bumped) {
                newDate = Calendar.current.date(byAdding: oneDay, to: date)!
            }
            if dayOfMonth > 0 {
                newDate = Calendar.current.date(bySetting: .day, value: dayOfMonth, of: newDate)!
            }
            if dayOfWeek > 0 {
                var dow = DateUtils.shared.dayOfWeekForDate(newDate)
                while dow != dayOfWeek {
                    newDate = Calendar.current.date(byAdding: oneDay, to: newDate)!
                    dow = DateUtils.shared.dayOfWeekForDate(newDate)
                }
            }
            return DateUtils.shared.ymdFromDate(newDate)
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
        
        var word = RecursWord()
        
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
            } else if word.hasData {
                processWord(word: word)
                word = RecursWord()
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
    
    func processAlpha(word: RecursWord) {
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
    
    /// One word parsed from the recurs value
    class RecursWord {
        
        var word = ""
        var lower = ""
        var number = 0
        
        var digits = 0
        var letters = 0
        
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

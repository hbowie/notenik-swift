//
//  DateValue.swift
//  notenik
//
//  Created by Herb Bowie on 11/26/18.
//  Copyright © 2018-2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class DateValue: StringValue {
    
    var yyyy = ""
    var mm = ""
    var dd = ""
    
    var start = ""
    var end = ""
    
    var year1 = ""
    var year2 = ""
    
    var alphaMonth = false
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Set an initial value with year, month and day integers
    convenience init (year: Int, month: Int, day: Int) {
        self.init()
        yyyy = String(format: "%04d", year)
        
        if month > 0 && month <= 12 {
            mm = String(format: "%02d", month)
        } else {
            mm = ""
        }
        if day > 0 && day <= 31 {
            dd = String(format: "%02d", day)
        } else {
            dd = ""
        }
        set(ymdDate)
    }
    
    /// Use the provided format string to format the date.
    ///
    /// - Parameter with: The format string to be used.
    /// - Returns: The formatted date. 
    func format(with: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = with
        let possibleDate = date
        if possibleDate == nil {
            return ymdDate
        } else {
            return formatter.string(from: possibleDate!)
        }
    }
    
    /// Return an optional Date object based on the user's text input
    var date : Date? {
        return DateUtils.shared.dateFromYMD(ymdDate)
    }
    
    var year: Int? {
        return Int(yyyy)
    }
    
    var month: Int? {
        return Int(mm)
    }
    
    var day: Int? {
        return Int(dd)
    }
    
    /// See if two of these objects have equal keys
    static func == (lhs: DateValue, rhs: DateValue) -> Bool {
        return lhs.ymdDate == rhs.ymdDate
    }
    
    /// See which of these objects should come before the other in a sorted list
    static func < (lhs: DateValue, rhs: DateValue) -> Bool {
        return lhs.ymdDate < rhs.ymdDate
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        if yyyy.count > 0 {
            return ymdDate
        } else {
            return "9999-12-31"
        }
    }

    /// Return a full or partial date in a yyyy-MM-dd format.
    var ymdDate: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return yyyy + "-" + mm
        } else {
            return yyyy + "-" + mm + "-" + dd
        }
    }
    
    var dMyDate: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return "   " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        } else {
            return dd + " " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        }
    }
    
    /**
     Set the date's value to a new string, parsing the input and attempting to
     identify the year, month and date
     */
    override func set(_ value: String) {
        
        super.set(value)
        
        yyyy = ""
        mm = ""
        dd = ""
        alphaMonth = false
        
        let parseContext = ParseContext()
        
        var word = DateWord()
        var lastChar : Character = " "
        
        for c in value {
            if word.numbers && c == ":" {
                parseContext.lookingForTime = true
                word.colon = true
                word.append(c)
            } else if StringUtils.isDigit(c) {
                if word.letters {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.numbers = true
                word.append(c)
            } else if StringUtils.isAlpha(c) {
                if word.numbers {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.letters = true
                word.append(c)
            } else {
                if word.letters && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                    if c == "," && dd.count > 0 {
                        parseContext.lookingForTime = true
                    }
                }
                if c == "-"
                    && lastChar == " "
                    && mm.count > 0
                    && dd.count > 0
                    && !(parseContext.lookingForTime) {
                    parseContext.startOfDateRangeCompleted = true
                }
                
            } // end if c is some miscellaneous punctuation
            
            lastChar = c
        } // end for c in value
        if word.hasData {
            processWord(context: parseContext, word: word)
        }
        
        // Fill in year if not explicitly stated
        if yyyy.count == 0 && mm.count > 0 {
            let month:Int? = Int(mm)
            if year2.count > 0 && month != nil && month! < 7 {
                yyyy = year2
            } else {
                yyyy = year1
            }
            var year:Int? = Int(yyyy)
            if year == nil {
                year = 2012
            }
            // while (nextYear
            //     && ((year < CURRENT_YEAR)
            //         || (year == CURRENT_YEAR && month <= CURRENT_MONTH))) {
            //             year++;
            //            yyyy = zeroPad(year, 4);
            // }
        }
    } // end func set
    
    /**
     Process each parsed word once it's been completed.
     */
    func processWord(context: ParseContext, word: DateWord) {

        if word.letters {
            processWhenLetters(context: context, word: word)
        } else if word.numbers {
            processWhenNumbers(context: context, word: word)
        } else {
            // contains something other than digits or letters?
        }
    }
    
    /**
     Process a word containing letters.
     */
    func processWhenLetters(context: ParseContext, word: DateWord) {
        if word.lowercased() == "today" {
            self.value = DateUtils.shared.ymdToday
            self.yyyy  = DateUtils.shared.yyyyToday
            self.mm    = DateUtils.shared.mmToday
            self.dd    = DateUtils.shared.ddToday
        } else if word.lowercased() == "at"
            || word.lowercased() == "from" {
            context.lookingForTime = true
        } else if word.lowercased() == "am"
            || word.lowercased() == "pm" {
            if end.count > 0 {
                end.append(" ")
                end.append(word.word)
            } else if start.count > 0 {
                start.append(" ")
                start.append(word.word)
            }
        } else if mm.count > 0 && dd.count > 0 {
            // Don't overlay the first month if a range was supplied
        } else {
            let monthIndex = DateUtils.shared.matchMonthName(word.word)
            if monthIndex > 0 {
                if mm.count > 0 {
                    dd = String(mm)
                }
                mm = String(format: "%02d", monthIndex)
                alphaMonth = true
            }
        }
    }
    
    /**
     Process a word containing digits.
     */
    func processWhenNumbers(context: ParseContext, word: DateWord) {
        var number : Int?
        if !(word.colon) {
            number = Int(word.word)
        }
        if number != nil && number! > 1000 {
            yyyy = String(number!)
        } else if context.lookingForTime {
            if start.count == 0 {
                start.append(word.word)
            } else {
                end.append(word.word)
            }
        } else if context.startOfDateRangeCompleted {
            // Let's not overwrite the start of the range with an ending date
        } else {
            // Let's use the number as part of a date
            if mm.count == 0 && number != nil && number! >= 1 && number! <= 12 {
                mm = String(format: "%02d", number!)
            } else if dd.count == 0 && number != nil && number! >= 1 && number! <= 31 {
                dd = String(format: "%02d", number!)
            } else if yyyy.count == 0 {
                if number != nil && number! > 1900 {
                    yyyy = String(number!)
                } else if number != nil && number! > 9 {
                    yyyy = "20" + String(number!)
                } else if number != nil {
                    yyyy = "2000" + String(number!)
                }
            } // end if this might be our year
        } // end if we're just examining a normal number that is part of a date
    } // end of func processWhenNumbers
    
    /// An inner class containing the parsing context.
    class ParseContext {
        var lookingForTime = false
        var startOfDateRangeCompleted = false
    }
    
    /// An inner class representing one word parsed from a date string.
    class DateWord {
        var word = ""
        var lower = ""
        var numbers = false
        var letters = false
        var colon = false
        
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
    }
}

//
//  CalendarViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CalendarViewController: NSViewController {

    @IBOutlet var yearTextField: NSTextField!
    @IBOutlet var monthTextField: NSTextField!
    @IBOutlet var dayTextField: NSTextField!
    
    @IBOutlet var gridParent: NSView!
    
    var window: CalendarWindowController?
    var recursString = ""
    
    var calGrid: NSGridView!
    
    var headerRow: [NSView] = []
    var dayButtons: [[NSButton]] = []
    var gridViews: [[NSView]] = []
    
    var dateView: DateView?
    
    let gregCalendar = Calendar(identifier: .gregorian)
    var year = 2019
    var month = 04
    var daysInMonth = 30
    var day = 17
    
    var startingColumn = 0
    
    var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loaded = true
        displayYear()
        displayMonth()
        displayDay()
        formatCalendar()
        displayCalendar()
    }
    
    /// Set to Today's Date
    @IBAction func todayClicked(_ sender: Any) {
        let now = Date()
        year = gregCalendar.component(.year, from: now)
        month = gregCalendar.component(.month, from: now)
        day = gregCalendar.component(.day, from: now)
        displayYear()
        displayMonth()
        displayDay()
        displayCalendar()
    }
    
    /// Apply recur rules, if any
    @IBAction func recurClicked(_ sender: Any) {
        guard dateView != nil else { return }
        guard let recursView = dateView!.recursView else { return }
        let recurs = RecursValue(recursView.text)
        let date = DateValue(year: year, month: month, day: day)
        let newDate = DateValue(recurs.recur(date))
        let y = newDate.year
        if y != nil { year = y! }
        let m = newDate.month
        if m != nil { month = m! }
        let d = newDate.day
        if d != nil { day = d! }
        displayYear()
        displayMonth()
        displayDay()
        displayCalendar()
    }
    
    /// No Date
    @IBAction func naClicked(_ sender: Any) {
        guard dateView != nil else { return }
        dateView!.changeDate(year: 0, month: 0, day: 0)
        window!.close()
    }
    
    /// OK
    @IBAction func okClicked(_ sender: Any) {
        guard dateView != nil else { return }
        dateView!.changeDate(year: year, month: month, day: day)
        window!.close()
    }
    
    /// Put together the Calendar grid
    func formatCalendar() {
        

        // Let's start with the header row showing the day of week abbreviations
        var j = 1
        while j <= 7 {
            let dayOfWeekName = DateUtils.dayOfWeekNames[j]
            let dayOfWeekAbbrSub = dayOfWeekName.prefix(2)
            let dayOfWeekAbbr = String(dayOfWeekAbbrSub)
            let headerLabel = NSTextField(labelWithString: dayOfWeekAbbr)
            headerLabel.alignment = .center
            headerRow.append(headerLabel)
            j += 1
        }
        gridViews.append(headerRow)
        
        // Now let's create an array of buttons representing the days of the month
        var i = 1
        while i < 7 {
            var weekRow: [NSButton] = []
            j = 0
            while j < 7 {
                let dayButton = NSButton(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
                dayButton.setButtonType(.toggle)
                dayButton.isBordered = true
                dayButton.bezelStyle = .roundRect
                dayButton.attributedTitle = NSAttributedString(string: "00")
                dayButton.target = self
                dayButton.action = #selector(dayButtonClicked)
                weekRow.append(dayButton)
                j += 1
            }
            gridViews.append(weekRow)
            dayButtons.append(weekRow)
            i += 1
        }
        calGrid = NSGridView(views: gridViews)
        calGrid.translatesAutoresizingMaskIntoConstraints = false
        gridParent.addSubview(calGrid)
        
        // Pin the grid to the edges of our main view
        calGrid.leadingAnchor.constraint(equalTo: gridParent.leadingAnchor, constant: 0).isActive = true
        calGrid.trailingAnchor.constraint(equalTo: gridParent.trailingAnchor, constant: 0).isActive = true
        calGrid.topAnchor.constraint(equalTo: gridParent.topAnchor, constant: 0).isActive = true
        calGrid.bottomAnchor.constraint(equalTo: gridParent.bottomAnchor, constant: -0).isActive = true
    }
    
    /// Accept the user's selection of a new day
    @objc func dayButtonClicked() {
        
        let firstDayOfMonth = DateUtils.shared.dateFromYMD(year: year, month: month, day: 01)
        let firstDayOfWeek = DateUtils.shared.dayOfWeekForDate(firstDayOfMonth!)
        var workDay = 1
        var workMonth = month
        var workDaysInMonth = daysInMonth
        if startingColumn > 0 {
            workMonth = priorMonth(month)
            workDaysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: workMonth)
            workDay = workDaysInMonth - firstDayOfWeek + 2
        }
        
        var dateChanged = false
        var i = 0
        
        while i < 6 {
            var j = 0
            while j < 7 {
                if dayButtons[i][j].state == .on {
                    if !dateChanged && (day != workDay || month != workMonth) {
                        dateChanged = true
                        day = workDay
                        if workMonth < month || (workMonth > month && workMonth == 12){
                            month = workMonth
                            if month == 12 {
                                year -= 1
                                displayYear()
                            }
                            displayMonth()
                        } else if workMonth > month || workMonth < month && workMonth == 1 {
                            month = workMonth
                            if month == 1 {
                                year += 1
                                displayYear()
                            }
                            displayMonth()
                        }
                        displayDay()
                    }
                }
                j += 1
                
                workDay += 1
                if workDay > workDaysInMonth {
                    workDay = 1
                    workMonth = nextMonth(workMonth)
                    workDaysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: workMonth)
                }
            }
            i += 1
        }
        if dateChanged {
            displayCalendar()
        }
    }
    
    /// Update the button titles and styles to reflect the specified date
    func displayCalendar() {
        guard year > 0 && month >= 1 && month <= 12 else { return }
        
        let lightFont = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .light)
        let regularFont = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        let boldFont = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        
        let otherMonthAttrs = [NSAttributedString.Key.font: lightFont]
        let otherDayAttrs = [NSAttributedString.Key.font: regularFont]
        let selectedDayAttrs = [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: NSColor.red]
        
        let firstDayOfMonth = DateUtils.shared.dateFromYMD(year: year, month: month, day: 01)
        let firstDayOfWeek = DateUtils.shared.dayOfWeekForDate(firstDayOfMonth!)
        var i = 0
        var j = 0
        startingColumn = firstDayOfWeek - 1
        var workDay = 1
        var workMonth = month
        var workDaysInMonth = daysInMonth
        if startingColumn > 0 {
            workMonth = priorMonth(month)
            workDaysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: workMonth)
            workDay = workDaysInMonth - firstDayOfWeek + 2
        }
        while i < 6 {
            let dayOfMonthStr = String(format: "%02d", workDay)
            if workMonth == month {
                dayButtons[i][j].attributedTitle = NSAttributedString(string: dayOfMonthStr, attributes: otherDayAttrs)
                if workDay == day {
                    dayButtons[i][j].state = .on
                } else {
                    dayButtons[i][j].state = .off
                }
            } else {
                dayButtons[i][j].attributedTitle = NSAttributedString(string: dayOfMonthStr, attributes: otherMonthAttrs)
                dayButtons[i][j].state = .off
            }
            dayButtons[i][j].attributedAlternateTitle = NSAttributedString(string: dayOfMonthStr, attributes: selectedDayAttrs)
            
            if j < 6 {
                j += 1
            } else {
                i += 1
                j = 0
            }
            workDay += 1
            if workDay > workDaysInMonth {
                workDay = 1
                workMonth = nextMonth(workMonth)
                workDaysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: workMonth)
            }
        }
    }
    
    func setYear(withInt yearInt: Int) {
        year = yearInt
        if loaded {
            displayYear()
        }
        calcDaysInMonth()
    }
    
    func setMonth(withInt monthInt: Int) {
        month = monthInt
        if loaded {
            displayMonth()
        }
        calcDaysInMonth()
    }
    
    func setDay(withInt dayInt: Int) {
        day = dayInt
        if loaded {
            displayDay()
            displayCalendar()
        }
    }
    
    @IBAction func bumpYearDown(_ sender: Any) {
        year -= 1
        displayYear()
        calcDaysInMonth()
    }
    
    @IBAction func bumpYearUp(_ sender: Any) {
        year += 1
        displayYear()
        calcDaysInMonth()
    }
    
    @IBAction func bumpMonthDown(_ sender: Any) {
        if month > 1 {
            month -= 1
        } else {
            month = 12
            year -= 1
            displayYear()
        }
        displayMonth()
        calcDaysInMonth()
    }
    
    @IBAction func bumpMonthUp(_ sender: Any) {
        if month < 12 {
            month += 1
        } else {
            month = 1
            year += 1
            displayYear()
        }
        displayMonth()
        calcDaysInMonth()
        displayCalendar()
    }
    
    func displayYear() {
        let strYear = String(year)
        yearTextField.stringValue = strYear
    }
    
    func displayMonth() {
        if month >= 1 && month <= 12 {
            let monthName = DateUtils.monthNames[month]
            monthTextField.stringValue = monthName
        }
    }
    
    func calcDaysInMonth() {
        daysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: month)
        if day > daysInMonth {
            day = daysInMonth
            displayDay()
        }
    }
    
    @IBAction func bumpDayDown(_ sender: Any) {
        if day > 1 {
            day -= 1
        } else {
            bumpMonthDown(sender)
            day = daysInMonth
        }
        displayDay()
        displayCalendar()
    }
    
    @IBAction func bumpDayUp(_ sender: Any) {
        if day < daysInMonth {
            day += 1
        } else {
            bumpMonthUp(sender)
            day = 1
        }
        displayDay()
        displayCalendar()
    }
    
    func displayDay() {
        let strDay = String(day)
        dayTextField.stringValue = strDay
    }
    
    func priorMonth(_ m: Int) -> Int {
        if m > 1 {
            return m - 1
        } else {
            return 12
        }
    }
    
    func nextMonth(_ m: Int) -> Int {
        if m < 12 {
            return m + 1
        } else {
            return 1
        }
    }
    
}

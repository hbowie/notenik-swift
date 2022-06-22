//
//  DateView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

/// Custom Edit View for a Date
class DateView: MacEditView {
    
    let appPrefs = AppPrefs.shared
    let appPrefsCocoa = AppPrefsCocoa.shared
    
    var stack: NSStackView!
    var textField: NSTextField!
    var calendarButton: NSButton!
    var recurButton: NSButton!
    var todayButton: NSButton!
    
    let calendarStoryboard: NSStoryboard = NSStoryboard(name: "Calendar", bundle: nil)
    
    var recursView: MacEditView?
    
    var view: NSView {
        return stack
    }
    
    var text: String {
        get {
            return textField.stringValue
        }
        set {
            textField.stringValue = newValue
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        
        var controls = [NSView]()
        
        textField = NSTextField()
        controls.append(textField)
        
        let todayTitle = appPrefsCocoa.makeUserAttributedString(text: "Today", usage: .text)
        todayButton = NSButton(title: "Today", target: self, action: #selector(todayButtonClicked))
        todayButton.attributedTitle = todayTitle
        controls.append(todayButton)
        
        let calendarTitle = appPrefsCocoa.makeUserAttributedString(text: "Calendar", usage: .text)
        calendarButton = NSButton(title: "Calendar", target: self, action: #selector(calendarButtonClicked))
        calendarButton.attributedTitle = calendarTitle
        controls.append(calendarButton)
        
        let recurTitle = appPrefsCocoa.makeUserAttributedString(text: "Recur", usage: .text)
        recurButton = NSButton(title: "Recur", target: self, action: #selector(recurButtonClicked))
        recurButton.attributedTitle = recurTitle
        controls.append(recurButton)
        
        stack = NSStackView(views: controls)
        stack.orientation = .horizontal
        
        AppPrefsCocoa.shared.setTextEditingFont(object: textField)
        
    }
    
    /// Set the Date Value to Today's Date, in 'dd MMM yyy' format
    @objc func todayButtonClicked() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        let dateStr = formatter.string(from: now)
        text = dateStr
    }

    @objc func calendarButtonClicked() {

        if let calendarController = self.calendarStoryboard.instantiateController(withIdentifier: "calendarWC") as? CalendarWindowController {
            calendarController.showWindow(self)
            let vc = calendarController.contentViewController as? CalendarViewController
            if text.count == 0 {
                vc!.todayClicked(self)
            } else {
                let dateValue = DateValue(text)
                
                let yyyy = dateValue.yyyy
                let yearInt = Int(yyyy)
                if yearInt != nil && yearInt! > 0 {
                    vc!.setYear(withInt: yearInt!)
                }
                
                let mm = dateValue.mm
                let monthInt = Int(mm)
                if monthInt != nil && monthInt! > 0 && monthInt! < 13 {
                    vc!.setMonth(withInt: monthInt!)
                }
                
                let dd = dateValue.dd
                let dayInt = Int(dd)
                if dayInt != nil && dayInt! > 0 && dayInt! < 32 {
                    vc!.setDay(withInt: dayInt!)
                }
            }
            
            vc!.dateView = self
            // vc!.recursString = 
            
        } else {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "DateView",
                              level: .fault,
                              message: "Couldn't get a Calendar Window Controller!")
        }
    }
    
    @objc func recurButtonClicked() {
        applyRecursRule()
    }
    
    func applyRecursRule() {
        guard recursView != nil else { return }
        let recurs = RecursValue(recursView!.text)
        let date = DateValue(text)
        let newDate = recurs.recur(date)
        text = newDate.description
    }
    
    /// Change Date - Called from CalendarViewController
    func changeDate(year: Int, month: Int, day: Int) {
        var dateStr = ""
        if day > 0 && day <= 31 {
            let dayStr = String(format: "%02d", day)
            dateStr.append(dayStr)
            dateStr.append(" ")
        }
        if month > 0 && month <= 12 {
            dateStr.append(DateUtils.shared.getShortMonthName(for: month))
            dateStr.append(" ")
        }
        if year > 0 {
            let yearStr = String(format: "%04d", year)
            dateStr.append(yearStr)
        }
        text = dateStr
    }
    
}

//
//  DateInsertViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/7/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class DateInsertViewController: NSViewController {
    
    let prefs = AppPrefs.shared
    
    var collectionController: CollectionWindowController?
    var wc: DateInsertWindowController?
    
    @IBOutlet weak var todayButton:     NSButton!
    @IBOutlet weak var tomorrowButton:  NSButton!
    @IBOutlet weak var nextWeekButton:  NSButton!
    @IBOutlet weak var nextMonthButton: NSButton!
    @IBOutlet weak var nextYearButton:  NSButton!
    
    @IBOutlet weak var format1Button: NSButton!
    @IBOutlet weak var format2Button: NSButton!
    @IBOutlet weak var format3Button: NSButton!
    @IBOutlet weak var customFormatButton: NSButton!
    @IBOutlet weak var customFormatText: NSTextField!
    
    @IBOutlet weak var dateResultTextField: NSTextField!
    
    let calendar = Calendar.current
    var date = Date()
    var formatter = DateFormatter()
    var formatted = ""

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let content = prefs.dateContent
        switch content {
        case "today":
            todayButton.state = .on
        case "tomorrow":
            tomorrowButton.state = .on
        case "next-week":
            nextWeekButton.state = .on
        case "next-month":
            nextMonthButton.state = .on
        case "next-year":
            nextYearButton.state = .on
        default:
            todayButton.state = .on
        }
        
        let format = prefs.dateFormat
        switch format {
        case "format-1":
            format1Button.state = .on
        case "format-2":
            format2Button.state = .on
        case "format-3":
            format3Button.state = .on
        case "format-custom":
            customFormatButton.state = .on
        default:
            format1Button.state = .on
        }
        
        let customFormat = prefs.customDateFormat
        if customFormat.isEmpty {
            customFormatText.stringValue = "EEEE, MMMM d, yyyy"
        } else {
            customFormatText.stringValue = customFormat
        }
        
        generateFormattedDate()
    }
    
    @IBAction func contentButtonChanged(_ sender: Any) {
        if todayButton.state == .on {
            prefs.dateContent = "today"
        } else if tomorrowButton.state == .on {
            prefs.dateContent = "tomorrow"
        } else if nextWeekButton.state == .on {
            prefs.dateContent = "next-week"
        } else if nextMonthButton.state == .on {
            prefs.dateContent = "next-month"
        } else if nextYearButton.state == .on {
            prefs.dateContent = "next-year"
        }
        generateFormattedDate()
    }
    
    @IBAction func formatButtonChanged(_ sender: Any) {
        if format1Button.state == .on {
            prefs.dateFormat = "format-1"
        } else if format2Button.state == .on {
            prefs.dateFormat = "format-2"
        } else if format3Button.state == .on {
            prefs.dateFormat = "format-3"
        } else if customFormatButton.state == .on && customFormatText.stringValue.count > 0 {
            prefs.dateFormat = "format-custom"
        }
        generateFormattedDate()
    }
    
    @IBAction func customFormatChanged(_ sender: Any) {
        prefs.customDateFormat = customFormatText.stringValue
        generateFormattedDate()
    }
    
    func generateFormattedDate() {
        
        // Get the desired date content.
        let now = Date()
        if todayButton.state == .on {
            date = now
        } else if tomorrowButton.state == .on {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                date = tomorrow
            }
        } else if nextWeekButton.state == .on {
            if let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) {
                date = nextWeek
            }
        } else if nextMonthButton.state == .on {
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
                date = nextMonth
            }
        } else if nextYearButton.state == .on {
            if let nextYear = calendar.date(byAdding: .year, value: 1, to: now) {
                date = nextYear
            }
        }
        
        // Now apply the desired format.
        if format1Button.state == .on {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        } else if format2Button.state == .on {
            formatter.dateFormat = "yyyy-MM-dd"
        } else if format3Button.state == .on {
            formatter.dateFormat = "dd MMM yyyy"
        } else if customFormatButton.state == .on && customFormatText.stringValue.count > 0 {
            formatter.dateFormat = customFormatText.stringValue
        }
        formatted = formatter.string(from: date)
        
        dateResultTextField.stringValue = formatted
        
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(formatted, forType: .string)
        closeWindow()
        if let collWC = collectionController {
            collWC.pasteTextNow()
        }
    }
    
    func closeWindow() {
        guard wc != nil else { return }
        wc!.close()
    }
}

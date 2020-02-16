//
//  Logger.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/18.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import os

class Logger {
    
    static let shared = Logger()
    
    var dateFormatter: DateFormatter
    var dateFormat: String
    
    var logDestPrint   = false
    var logDestWindow  = false
    var logDestUnified = true
    
    var logThreshold: LogLevel = .info
    
    var log = ""
    
    var oslogs = [String:OSLog]()
    
    init() {
        dateFormatter = DateFormatter()
        dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = dateFormat
    }
    
    /// Log a new event. 
    func log (_ event: LogEvent) {
        log(subsystem: event.subsystem,
            category: event.category,
            level: event.level,
            message: event.msg)
    }
    
    /// Process a loggable event
    func log (subsystem: String, category: String, level: LogLevel, message: String) {
        if level.rawValue >= logThreshold.rawValue {
            if logDestUnified {
                logToUnified(subsystem: subsystem, category: category, level: level, message: message)
            }
            guard logDestPrint || logDestWindow else { return }
            
            var logLine = ""
            let date = Date()
            logLine.append(dateFormatter.string(from: date) + " ")
            if subsystem.count > 0 {
                logLine.append(subsystem)
            }
            if category.count > 0 {
                logLine.append("/" + category)
            }
            logLine.append(" " )
            switch level  {
            case .info:
                logLine.append("Info: ")
            case .debug:
                logLine.append("DEBUG: ")
            case .error:
                logLine.append("Error! ")
            case .fault:
                logLine.append("FAULT!! ")
            }
            logLine.append(message)

            if logDestPrint {
                print(logLine)
            }
            
            if logDestWindow {
                log.append(message)
                log.append("\n")
            }
        }
    }
    
    func logToUnified (subsystem: String, category: String, level: LogLevel, message: String) {
        let logKey = subsystem + "/" + category
        var oslog = oslogs[logKey]
        if oslog == nil {
            oslog = OSLog(subsystem: subsystem, category: category)
            oslogs[logKey] = oslog
        }
        var logType: OSLogType = .info
        switch level {
        case .info:
            logType = .info
        case .debug:
            logType = .debug
        case .error:
            logType = .error
        case .fault:
            logType = .fault
        }
        os_log("%{PUBLIC}@", log: oslog!, type: logType, message)
    }
    
}

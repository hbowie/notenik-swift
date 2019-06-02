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
    
    var logDest: LogDestination = .print
    
    var logThreshold: LogLevel = .info
    
    var log = ""
    
    var oslogs = [String:OSLog]()
    
    init() {
        
    }
    
    /// Process a loggable event
    func log (subsystem: String, category: String, level: LogLevel, message: String) {
        if level.rawValue >= logThreshold.rawValue {
            switch logDest {
            case .print:
                print(message)
            case .window:
                log.append(message)
                log.append("\n")
            case .unified:
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
    }
    
    /// Write one line to the indicated destination
    func writeLine (_ line : String) {

    }
}

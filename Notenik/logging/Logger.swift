//
//  Logger.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class Logger {
    
    static let shared = Logger()
    
    var logDest: LogDestination = .print
    
    var logThreshold: LogLevel = .routine
    
    var log = ""
    
    init() {
        
    }
    
    /// Process a loggable event
    func log (skip : Bool, indent : Int, level : LogLevel, message : String) {
        if level.rawValue >= logThreshold.rawValue {
            if skip {
                writeLine(" ")
            }
            writeLine(message)
        }
    }
    
    /// Write one line to the indicated destination
    func writeLine (_ line : String) {
        switch logDest {
        case .print:
            print(line)
        case .window:
            log.append(line)
            log.append("\n")
        }
    }
}

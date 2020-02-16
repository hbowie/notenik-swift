//
//  LogEvent.swift
//  Notenik
//
//  Created by Herb Bowie on 6/1/19.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class LogEvent {
    var subsystem = "com.powersurgepub.notenik"
    var category = ""
    var level: LogLevel = .info
    var msg = ""
    
    init (subsystem: String, category: String, level: LogLevel, message: String) {
        self.subsystem = subsystem
        self.category = category
        self.level = level
        self.msg = message
    }
}

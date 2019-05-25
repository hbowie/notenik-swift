//
//  Field.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

enum FieldType: Int {
    case defaultType    = 0
    case string         = 1
    case title          = 2
    case body           = 3
    case longText       = 4
    case tags           = 5
    case link           = 6
    case label          = 7
    case author         = 8
    case date           = 9
    case rating         = 10
    case status         = 11
    case seq            = 12
    case index          = 13
    case recurs         = 14
    case code           = 15
    case dateAdded      = 16
    case work           = 17
    case pickFromList   = 18
}


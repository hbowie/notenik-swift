//
//  Field.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

enum FieldType : Int {
    case defaultType    = 0
    case string         = 1
    case title          = 2
    case longText       = 3
    case tags           = 4
    case link           = 5
    case label          = 6
    case author         = 7
    case date           = 8
    case rating         = 9
    case status         = 10
    case seq            = 11
    case index          = 12
    case recurs         = 13
    case code           = 14
    case dateAdded      = 15
    case work           = 16
    case pickFromList   = 17
}


//
//  MkdownChunk.swift
//  Notenik
//
//  Created by Herb Bowie on 3/3/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MkdownChunk {
    var text = ""
    var type: MkdownChunkType = .plaintext
    var startsWithSpace = false
    var endsWithSpace = false
    
    var spaceBefore = true
    var _spaceAfter = true
    var spaceAfter: Bool {
        get {
            return _spaceAfter
        }
        set {
            _spaceAfter = newValue
            if spaceBefore && _spaceAfter {
                if emphasisChar {
                    type = .literal
                }
            }
        }
    }
    
    var emphasisChar: Bool {
        return type == .asterisk || type == .underline
    }
    
    func setTextFrom(char: Character) {
        text = String(char)
    }
    
    func display(title: String = "", indenting: Int = 0) {
        print(" ")
        let indent = String(repeating: " ", count: indenting)
        if title.count > 0 {
            print("\(indent)\(title)")
        }
        print("\(indent)text: \(text)")
        print("\(indent)type: \(type)")
    }
}

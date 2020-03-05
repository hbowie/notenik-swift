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
    
    func setTextFrom(char: Character) {
        text = String(char)
    }
    
    func display() {
        print("text: \(text)")
        print("type: \(type)")
    }
}

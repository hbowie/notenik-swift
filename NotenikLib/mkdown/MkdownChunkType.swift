//
//  MkdownChunkType.swift
//  Notenik
//
//  Created by Herb Bowie on 3/3/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

enum MkdownChunkType {
    case plaintext
    
    case asterisk
    case underline
    
    case startStrong1
    case startStrong2
    case endStrong1
    
    case endStrong2
    case startEmphasis
    case endEmphasis
    
    case backSlash
    case escaped
}

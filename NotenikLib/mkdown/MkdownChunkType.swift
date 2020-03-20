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
    case literal
    
    case backtickQuote
    case startCode
    case endCode
    case backtickQuote2
    case skipSpace
    
    case leftAngleBracket
    case tagStart
    
    case rightAngleBracket
    
    case ampersand
    case entityStart
    
    case leftSquareBracket
    case rightSquareBracket
    
    case leftParen
    case rightParen
    
    case exclamationMark
    case startImage
    
    case singleQuote
    case doubleQuote
    
    case startLinkText
    case startWikiLink1
    case startWikiLink2
    
    case endLinkText
    case endWikiLink1
    case endWikiLink2
    
    case startLinkLabel
    case endLinkLabel
    
    case startLink
    case endLink
    
    case startTitle
    case endTitle
}

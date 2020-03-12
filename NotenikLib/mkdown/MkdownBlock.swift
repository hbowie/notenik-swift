//
//  MkdownBlock.swift
//  Notenik
//
//  Created by Herb Bowie on 3/6/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MkdownBlock: CustomStringConvertible, Equatable, NSCopying {

    var tag = ""
    var itemNumber = 0
    
    init() {
        
    }
    
    init(_ tag: String) {
        self.tag = tag
    }
    
    var description: String {
        if itemNumber == 0 {
            return tag
        } else {
            return "\(tag) # \(itemNumber)"
        }
    }
    
    var isHeadingTag: Bool {
        return tag.count == 2 && tag.starts(with: "h") && tag.last! >= "1" && tag.last! <= "6"
    }
    
    var isParagraph: Bool {
        return tag == "p"
    }
    
    var isBlockquote: Bool {
        return tag == "blockquote"
    }
    
    /// Increment the Heading Level by 1, and adjust appropriate variables. Return false if this
    /// does not result in a valid, incremented heading tag ('h1' thru 'h6').
    func incrementHeadingLevel() -> Bool {
        guard tag.count == 2 && tag.starts(with: "h") else { return false }
        let levelChar = tag.last!
        let levelString = String(levelChar)
        var level = Int(levelString)
        guard level != nil else { return false }
        guard level! < 6 else { return  false }
        level! += 1
        tag = "h\(level!)"
        return true
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = MkdownBlock(self.tag)
        copy.itemNumber = self.itemNumber
        return copy
    }
    
    func display(index: Int) {
        print("Block # \(index) Tag: \(tag), Item Number: \(itemNumber)")
    }
    
    static func == (lhs: MkdownBlock, rhs: MkdownBlock) -> Bool {
        return lhs.tag == rhs.tag && lhs.itemNumber == rhs.itemNumber
    }
}

//
//  MkdownBlockStack.swift
//  Notenik
//
//  Created by Herb Bowie on 3/6/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MkdownBlockStack: Equatable {

    let nullBlock = MkdownBlock()
    var blocks: [MkdownBlock] = []
    
    var lastIndex: Int { return blocks.count - 1 }
    
    var count: Int {
        return blocks.count
    }
    
    func append(_ tag: String) {
        blocks.append(MkdownBlock(tag))
    }
    
    func append(_ newBlock: MkdownBlock) {
        blocks.append(newBlock)
    }
    
    func removeLast() {
        if blocks.count > 0 {
            blocks.removeLast()
        }
    }
    
    var last: MkdownBlock {
        if blocks.count == 0 {
            return nullBlock
        } else {
            return blocks[blocks.count - 1]
        }
    }
    
    func incrementHeadingLevel() -> Bool {
        if blocks.count == 0 || !blocks[lastIndex].isHeadingTag {
            blocks.append(MkdownBlock("h1"))
            return true
        } else {
            return blocks[lastIndex].incrementHeadingLevel()
        }
    }
    
    func continueBlock(from: MkdownBlockStack, forLevel: Int) -> Bool {
        guard from.count >= forLevel else { return false }
        guard self.count < forLevel else { return false }
        let copy = from.blocks[forLevel].copy()
        let copiedBlock = copy as! MkdownBlock
        append(copiedBlock)
        return true
    }
    
    func display() {
        var i = 0
        for block in blocks {
            block.display(index: i)
            i += 1
        }
    }
    
    static func == (lhs: MkdownBlockStack, rhs: MkdownBlockStack) -> Bool {
        guard lhs.blocks.count == rhs.blocks.count else { return false }
        var index = lhs.blocks.count - 1
        while index >= 0 {
            if lhs.blocks[index] != rhs.blocks[index] {
                return false
            }
            index -= 1
        }
        return true
    }
}

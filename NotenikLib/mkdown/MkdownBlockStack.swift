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
    
    /// Continue a block from a previous line.
    /// - Parameters:
    ///   - from: The previous line.
    ///   - forLevel: 1 for the first level, 2 for the second, etc.
    func continueBlock(from: MkdownBlockStack, forLevel: Int) -> Bool {
        var levelCount = 0
        var index = 0
        while levelCount < forLevel && index < from.count {
            levelCount += 1
            let indexPlus = index + 1
            var indexInc = 1
            if (indexPlus < from.count
                && from.blocks[index].isListTag
                && from.blocks[indexPlus].isListItem) {
                indexInc = 2
            }
            
            if levelCount == forLevel {
                let copy1 = from.blocks[index].copy() as! MkdownBlock
                append(copy1)
                if indexInc == 2 {
                    var copy2: MkdownBlock? = nil
                    copy2 = from.blocks[indexPlus].copy() as? MkdownBlock
                    if copy2 != nil {
                        append(copy2!)
                    }
                }
            }
            index += indexInc
        }
        return levelCount == forLevel
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

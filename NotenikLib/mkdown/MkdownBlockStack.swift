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

/// All of the block tags enclosing one or more lines of Markdown/HTML. 
class MkdownBlockStack: Equatable {

    let nullBlock = MkdownBlock()
    
    var blocks: [MkdownBlock] = []
    var count: Int { return blocks.count }
    var lastIndex: Int { return count - 1 }
    
    var listPointers: [Int] = []
    
    /// Return the list block at the requested level (with the first level denoted by zero). 
    func getListBlock(atLevel: Int) -> MkdownBlock {
        guard atLevel >= 0 && atLevel < listPointers.count else { return nullBlock }
        let listPointer = listPointers[atLevel]
        guard listPointer >= 0 && listPointer < blocks.count else { return nullBlock }
        let listBlock = blocks[listPointer]
        guard listBlock.isListTag else { return nullBlock }
        return listBlock
    }
    
    /// Return the list block at the requested level (with the first level denoted by zero).
    func getListItem(atLevel: Int) -> MkdownBlock {
        guard atLevel >= 0 && atLevel < listPointers.count else { return nullBlock }
        let listItemPointer = listPointers[atLevel] + 1
        guard listItemPointer >= 0 && listItemPointer < blocks.count else { return nullBlock }
        let listItemBlock = blocks[listItemPointer]
        guard listItemBlock.tag == "li" else { return nullBlock }
        return listItemBlock
    }
    
    func append(_ tag: String) {
        let block = MkdownBlock(tag)
        append(block)
    }
    
    func append(_ newBlock: MkdownBlock) {
        blocks.append(newBlock)
        if newBlock.isListTag {
            listPointers.append(blocks.count - 1)
        }
    }
    
    func removeLast() {
        if blocks.count > 0 {
            let lastBlock = blocks.removeLast()
            if lastBlock.isListTag {
                listPointers.removeLast()
            }
        }
    }
    
    var last: MkdownBlock {
        if blocks.count == 0 {
            return nullBlock
        } else {
            return blocks[lastIndex]
        }
    }
    
    /// Does this stack have a paragraph tag as its last block?
    var hasParaTag: Bool {
        return last.tag == "p"
    }
    
    /// Add a paragraph block to this stack, if we don't already have one. 
    func addParaTag() {
        if !hasParaTag {
            append("p")
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
    
    func display() {
        var i = 0
        for block in blocks {
            block.display(index: i)
            i += 1
        }
    }
    
    /// Test for equality. 
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

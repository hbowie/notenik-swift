//
//  MkdownLine.swift
//  Notenik
//
//  Created by Herb Bowie on 2/25/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// One line in Markdown syntax.
class MkdownLine {
    var line = ""
    var type: MkdownLineType = .blank
    var blocks = MkdownBlockStack()
    var quoteLevel = 0
    var hashCount = 0
    var headingLevel = 0
    
    var repeatingChar: Character = " "
    var repeatCount = 0
    var onlyRepeating = true
    var onlyRepeatingAndSpaces = true
    
    var leadingBulletAndSpace = false
    
    var headingUnderlining: Bool {
        return (onlyRepeating && repeatCount >= 2 &&
            (repeatingChar == "=" || repeatingChar == "-"))
    }
    
    var horizontalRule: Bool {
        return onlyRepeatingAndSpaces && repeatCount >= 3 &&
            (repeatingChar == "-" || repeatingChar == "*" || repeatingChar == "_")
    }
    
    var textFound = false
    var text = ""

    var trailingSpaceCount = 0
    var endsWithNewline = false
    var endsWithBackSlash = false
    
    var isEmpty: Bool {
        return line.count == 0 && !endsWithNewline
    }
    
    var endsWithLineBreak: Bool {
        return type != .blank && trailingSpaceCount >= 2
    }
    
    var indentLevels = 0
    
    func makeCode() {
        type = .code
        blocks.append("pre")
        blocks.append("code")
    }
    
    func makeHeading1() {
        type = .heading
        headingLevel = 1
        if blocks.last.isHeadingTag || blocks.last.isParagraph {
            blocks.last.tag = "h1"
        } else {
            blocks.append("h1")
        }
    }
    
    func makeHeading2() {
        type = .heading
        headingLevel = 2
        if blocks.last.isHeadingTag || blocks.last.isParagraph {
            blocks.last.tag = "h2"
        } else {
            blocks.append("h2")
        }
    }
    
    /// Another hash symbol
    func incrementHeadingLevel() -> Bool {
        hashCount += 1
        if blocks.last.isHeadingTag {
            let ok = blocks.incrementHeadingLevel()
            if !ok {
                return false
            }
        } else {
            blocks.append("h1")
        }
        type = .heading
        headingLevel += 1
        return true
    }
    
    func makeOrdinary() {
        type = .ordinaryText
        headingLevel = 0
        if blocks.last.isHeadingTag {
            blocks.removeLast()
        }
    }
    
    func makeHTML() {
        type = .html
    }
    
    func makeHorizontalRule() {
        type = .horizontalRule
    }
    
    func carryBlockquotesForward(lastLine: MkdownLine) {
        var insertionPoint = 0
        for block in lastLine.blocks.blocks {
            if block.isBlockquote {
                blocks.blocks.insert(MkdownBlock("blockquote"), at: insertionPoint)
                insertionPoint += 1
            } else {
                return
            }
        }
    }
    
    func makeUnordered(previousLine: MkdownLine, previousNonBlankLine: MkdownLine) {
        
        type = .unorderedItem
        
        blocks.append("ul")
        let liIndex = blocks.count
        blocks.append("li")
        blocks.blocks[liIndex].itemNumber = 1
        
        var lastPossibleListItem = previousLine
        if previousLine.type == .blank {
            lastPossibleListItem = previousNonBlankLine
        }
        
        guard lastPossibleListItem.type == .orderedItem else { return }
        
        guard blocks.count == lastPossibleListItem.blocks.count
            || blocks.count == lastPossibleListItem.blocks.count - 1 else {
            return
        }
        
        blocks.blocks[liIndex].itemNumber = previousLine.blocks.blocks[liIndex].itemNumber + 1
        
        if previousLine.type == .blank {
            previousLine.blocks.append("ul")
            previousNonBlankLine.addParagraph()
            self.addParagraph()
        }
    }
    
    func makeOrdered(previousLine: MkdownLine, previousNonBlankLine: MkdownLine) {
        
        type = .orderedItem
        
        blocks.append("ol")
        let liIndex = blocks.count
        blocks.append("li")
        blocks.blocks[liIndex].itemNumber = 1
        
        var lastPossibleListItem = previousLine
        if previousLine.type == .blank {
            lastPossibleListItem = previousNonBlankLine
        }
        
        guard lastPossibleListItem.type == .orderedItem else { return }
        
        guard blocks.count == lastPossibleListItem.blocks.count
            || blocks.count == lastPossibleListItem.blocks.count - 1 else {
            return
        }
        
        // print("Make Ordered")
        // print("Current Line:")
        // display()
        // print("Previous Line:")
        // previousLine.display()
        // print("Previous non-blank line:")
        // previousNonBlankLine.display()
        // print("liIndex: \(liIndex)")
        blocks.blocks[liIndex].itemNumber = lastPossibleListItem.blocks.blocks[liIndex].itemNumber + 1
        
        if previousLine.type == .blank {
            previousLine.blocks.append("ol")
            previousNonBlankLine.addParagraph()
            self.addParagraph()
        }
        
    }
    
    func continueBlock(from: MkdownLine, forLevel: Int) -> Bool {
        return blocks.continueBlock(from: from.blocks, forLevel: forLevel)
    }
    
    func addParagraph() {
        if blocks.last.tag != "p" {
            blocks.append("p")
        }
    }
    
    func display() {
        print(" ")
        print("MkdownLine.display")
        print("Input line: '\(line)'")
        print("Line type: \(type)")
        if indentLevels > 0 {
            print("Indent levels: \(indentLevels)")
        }
        if type == .heading {
            print("Heading level: \(headingLevel)")
        }
        if isEmpty {
            print("Is Empty? \(isEmpty)")
        }
        if quoteLevel > 0 {
            print("Quote Level = \(quoteLevel)")
        }
        if hashCount > 0 {
            print("Hash count: \(hashCount)")
        }
        if repeatCount > 0 {
            print("Repeating char of \(repeatingChar), repeated \(repeatCount) times, only repeating chars? \(onlyRepeating)")
        }
        if headingUnderlining {
            print("Heading Underlining")
        }
        if trailingSpaceCount > 0 {
            print ("Trailing space count: \(trailingSpaceCount)")
        }
        if endsWithLineBreak {
            print("Ends with line break? \(endsWithLineBreak)")
        }
        if horizontalRule {
            print("Horizontal Rule")
        }
        print("Text: '\(text)'")
        blocks.display()
    }
}

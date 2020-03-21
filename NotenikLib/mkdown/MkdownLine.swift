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
    var headingNumber = 0
    
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
    
    func makeHeading(level: Int, headingNumbers: inout [Int]) {
        
        var clear = headingNumbers.count - 1
        while clear > level {
            headingNumbers[clear] = 0
            clear -= 1
        }
        
        preserveHeadingNumber(level: level, headingNumbers: &headingNumbers)
        headingNumbers[level] = headingNumber
        
        type = .heading
        headingLevel = level
        if blocks.last.isHeadingTag || blocks.last.isParagraph {
            blocks.last.tag = "h\(level)"
        } else {
            blocks.append("h\(level)")
        }
    }
    
    /// If this line started with ordered item numbering, then take actions to preserve
    /// the number.
    func preserveHeadingNumber(level: Int, headingNumbers: inout [Int]) {
        
        guard type == .orderedItem else { return }
        
        if headingNumbers[level] > 0 {
            headingNumber = headingNumbers[level] + 1
        } else {
            headingNumber = 1
        }
        
        let liIndex = blocks.count - 1
        let listIndex = blocks.count - 2
        if liIndex > 0 && blocks.blocks[liIndex].isListItem {
            blocks.blocks.remove(at: liIndex)
            if listIndex >= 0 && blocks.blocks[listIndex].tag == "ol" {
                blocks.blocks.remove(at: listIndex)
            }
        }
    }
    
    /// Another hash symbol
    func incrementHashCount() -> Bool {
        hashCount += 1
        return hashCount >= 1 && hashCount <= 6
    }
    
    func makeOrdinary() {
        type = .ordinaryText
        headingLevel = 0
        if blocks.last.isHeadingTag {
            blocks.removeLast()
        }
    }
    
    func makeFollowOn(previousLine: MkdownLine) {
        type = .followOn
        blocks = MkdownBlockStack()
        for block in previousLine.blocks.blocks {
            self.blocks.append(block)
        }
    }
    
    var followOn: Bool {
        return type == .followOn
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
    
    /// Make this line an unordered (bulleted) list item.
    func makeUnordered(previousLine: MkdownLine, previousNonBlankLine: MkdownLine) {
        makeListItem(requestedType: .unorderedItem,
                     previousLine: previousLine,
                     previousNonBlankLine: previousNonBlankLine)
    }
    
    /// Make this line an ordered (numbered) list item.
    func makeOrdered(previousLine: MkdownLine, previousNonBlankLine: MkdownLine) {
        
        makeListItem(requestedType: .orderedItem,
                     previousLine: previousLine,
                     previousNonBlankLine: previousNonBlankLine)
    }
    
    /// Make this line a list item of the prescribed type.
    func makeListItem(requestedType: MkdownLineType,
                      previousLine: MkdownLine,
                      previousNonBlankLine: MkdownLine) {
        
        // Set the line type to the right sort of list.
        self.type = requestedType
        
        var listTag = "ul"
        if requestedType == .orderedItem {
            listTag = "ol"
        }
        
        // If the previous line was blank, then let's look at the last non-blank line.
        var lastPossibleListItem = previousLine
        if previousLine.type == .blank {
            lastPossibleListItem = previousNonBlankLine
        }
        
        // Is this the first item in a new list, or the
        // continuation of an existing list?
        let listIndex = self.blocks.listPointers.count
        var continueList = false
        var lastList = MkdownBlock()
        var lastListItem = MkdownBlock()
        if listIndex < lastPossibleListItem.blocks.listPointers.count {
            lastList = lastPossibleListItem.blocks.getListBlock(atLevel: listIndex)
            lastListItem = lastPossibleListItem.blocks.getListItem(atLevel: listIndex)
            if lastList.tag == listTag && lastListItem.tag == "li" {
                continueList = true
            }
        }
        
        let listItem = MkdownBlock("li")
        if continueList {
            if previousLine.type == .blank {
                lastList.listWithParagraphs = true
                if previousLine.blocks.listPointers.count <= listIndex {
                    previousLine.blocks.append(lastList)
                }
            }
            blocks.append(lastList)
            listItem.itemNumber = lastListItem.itemNumber + 1
        } else {
            let newList = MkdownBlock(listTag)
            blocks.append(newList)
            listItem.itemNumber = 1
        }
        blocks.append(listItem)
    }
    
    /// Try to continue open list blocks from previous lines, based on this line's indention level.
    /// - Parameters:
    ///   - previousLine: The line before this one.
    ///   - previousNonBlankLine: The last non-blank line before this one.
    ///   - forLevel: The indention level, where 1 means four spaces or a tab.
    /// - Returns: True if blocks were available and copied for the indicated level.
    func continueBlock(previousLine: MkdownLine,
                       previousNonBlankLine: MkdownLine,
                       forLevel: Int) -> Bool {
        
        // Which of the two passed lines should we examine?
        var lastPossibleListItem = previousLine
        if previousLine.type == .blank {
            lastPossibleListItem = previousNonBlankLine
        }
        
        // See whether we have list blocks to continue.
        let listIndex = forLevel - 1
        
        var continueList = false
        var lastList = MkdownBlock()
        var lastListItem = MkdownBlock()
        if listIndex < lastPossibleListItem.blocks.listPointers.count {
            lastList = lastPossibleListItem.blocks.getListBlock(atLevel: listIndex)
            lastListItem = lastPossibleListItem.blocks.getListItem(atLevel: listIndex)
            if lastList.isListTag && lastListItem.isListItem {
                continueList = true
                self.blocks.append(lastList)
                self.blocks.append(lastListItem)
                if previousLine.type == .blank
                    && previousLine.blocks.listPointers.count <= listIndex {
                    previousLine.blocks.append(lastList)
                    previousLine.blocks.append(lastListItem)
                }
            }
        }
        return continueList
    }
    
    func addParagraph() {
        blocks.addParaTag()
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
        if repeatCount > 1 {
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

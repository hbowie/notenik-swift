//
//  StringUtilsTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/6/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class StringUtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsDigit() {
        XCTAssertTrue(StringUtils.isDigit("0"))
        XCTAssertTrue(StringUtils.isDigit("3"))
        XCTAssertTrue(StringUtils.isDigit("9"))
        XCTAssertFalse(StringUtils.isDigit("a"))
        XCTAssertFalse(StringUtils.isDigit("-"))
    }
    
    func testIsAlpha() {
        XCTAssertTrue(StringUtils.isAlpha("a"))
        XCTAssertTrue(StringUtils.isAlpha("G"))
        XCTAssertTrue(StringUtils.isAlpha("Z"))
        XCTAssertFalse(StringUtils.isAlpha("!"))
        XCTAssertFalse(StringUtils.isAlpha("0"))
    }
    
    func testIsLower() {
        XCTAssertTrue(StringUtils.isLower("a"))
        XCTAssertTrue(StringUtils.isLower("g"))
        XCTAssertTrue(StringUtils.isLower("a"))
        XCTAssertFalse(StringUtils.isLower("A"))
        XCTAssertFalse(StringUtils.isLower("0"))
    }
    
    func testIsWhitespace() {
        XCTAssertTrue(StringUtils.isWhitespace(" "))
        XCTAssertTrue(StringUtils.isWhitespace("\t"))
        XCTAssertTrue(StringUtils.isWhitespace("\n"))
        XCTAssertFalse(StringUtils.isWhitespace("_"))
        XCTAssertFalse(StringUtils.isWhitespace("0"))
    }
    
    func testCharAt() {
        XCTAssertTrue(StringUtils.charAt(index: 0, str: "Herb Bowie") == "H")
        XCTAssertTrue(StringUtils.charAt(index: 1, str: "Herb Bowie") == "e")
        XCTAssertTrue(StringUtils.charAt(index: 2, str: "Herb Bowie") == "r")
    }
    
    func testIncrement() {
        XCTAssertTrue(StringUtils.increment("h") == "i")
        XCTAssertTrue(StringUtils.increment("z") == "a")
        XCTAssertTrue(StringUtils.increment("M") == "N")
        XCTAssertTrue(StringUtils.increment("Z") == "A")
        XCTAssertTrue(StringUtils.increment("5") == "6")
        XCTAssertTrue(StringUtils.increment("9") == "0")
        XCTAssertTrue(StringUtils.increment("0") == "1")
    }
    
    func testReplaceChar() {
        var str1 = "09"
        StringUtils.replaceChar(i: 1, str: &str1, newChar: "0")
        XCTAssertTrue(str1 == "00")
    }
    
    func testTrim() {
        XCTAssertTrue(StringUtils.trim(" test ") == "test")
    }
    
    func testTrimHeading() {
        XCTAssertTrue(StringUtils.trimHeading("Heading 1") == "Heading 1")
        XCTAssertTrue(StringUtils.trimHeading("   Heading 1   ") == "Heading 1")
        XCTAssertTrue(StringUtils.trimHeading("# Heading 1") == "Heading 1")
        XCTAssertTrue(StringUtils.trimHeading("# Heading 1 #") == "Heading 1")
    }
    
    func testToReadableFilename () {
        XCTAssertTrue(StringUtils.toReadableFilename("This is a file name") == "This is a file name")
    }
    
    func testLowerCaseFirst() {
        XCTAssertTrue(StringUtils.toLowerFirstChar("ALPHABET") == "aLPHABET")
    }
    
    func testUpperCaseFirst() {
        XCTAssertTrue(StringUtils.toUpperFirstChar("alphabet") == "Alphabet")
    }
    
    func testToCommonFileName() {
        XCTAssertTrue(StringUtils.toCommonFileName("File Name2 _Before") == "file-name2-before")
    }
    
    func testSummarize() {
        let startingText = "For progressives in the US -- and, indeed, in many parts of the world -- recent events have called into question our faith in the goodness of people, and in our continued march forward towards a better tomorrow. It's only been roughly a decade since those of us in the US were [celebrating in amazement the election of Barack Obama][obama] as our president, an event that seemed to usher in a new era of progressive values."
        let endingText = "For progressives in the US -- and, indeed, in many parts of the world -- recent events have called into question our faith in the goodness of people, and in our continued march forward towards a better tomorrow."
        XCTAssertTrue(StringUtils.summarize(startingText) == endingText)
    }
    
    func testConvertLinks() {
        let in1 = "Jump to https://www.amazon.com."
        let expected1 = "Jump to <a href=\"https://www.amazon.com\" target=\"ref\">https://www.amazon.com</a>."
        XCTAssertTrue(StringUtils.convertLinks(in1) == expected1)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

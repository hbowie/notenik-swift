//
//  LongTextValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class LongTextValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLongTextValue() {
        let text1 = LongTextValue("Line 1 \n")
        text1.appendLine("")
        XCTAssertTrue(text1.value == "Line 1 \n")
        text1.appendLine("Line 2")
        XCTAssertTrue(text1.value == "Line 1 \n\nLine 2\n")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

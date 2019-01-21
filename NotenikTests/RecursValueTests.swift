//
//  RecursValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 11/29/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class RecursValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRecursValue() {
        let recurs1 = RecursValue("Every Tuesday")
        XCTAssertTrue(recurs1.dayOfWeek == 3)
        let date1 = DateValue("2018-11-30")
        let date2 = DateValue(recurs1.recur(date1))
        XCTAssertTrue(date2.mm == "12")
        XCTAssertTrue(date2.yyyy == "2018")
        XCTAssertTrue(date2.dd == "11")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

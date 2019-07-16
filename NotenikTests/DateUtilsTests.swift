//
//  DateUtilsTests.swift
//  notenikTests
//
//  Created by Herb Bowie on 11/28/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest
@testable import Notenik

class DateUtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDateUtils() {
        let utils = DateUtils.shared
        XCTAssertTrue(utils.ymdToday == "2019-07-16")
        XCTAssertTrue(utils.matchMonthName("Feb") == 2)
        XCTAssertTrue(utils.matchMonthName("Tue") < 0)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

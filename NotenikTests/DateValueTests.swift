//
//  DateValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 11/29/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class DateValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDateValue() {
        let date1 = DateValue("Nov 29, 2018")
        XCTAssertTrue(date1.yyyy == "2018")
        XCTAssertTrue(date1.mm == "11")
        XCTAssertTrue(date1.dd == "29")
        
        let date2 = DateValue("Aug 31, 1967")
        XCTAssertTrue(date2.yyyy == "1967")
        XCTAssertTrue(date2.mm == "08")
        XCTAssertTrue(date2.dd == "31")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

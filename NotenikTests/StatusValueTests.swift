//
//  StatusValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/7/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class StatusValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStatusValue() {
        let config1 = StatusValueConfig()
        let status1 = StatusValue(str: "co", config: config1)
        XCTAssertTrue(status1.getInt() == 6)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

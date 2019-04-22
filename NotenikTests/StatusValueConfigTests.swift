//
//  StatusValueConfigTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/7/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class StatusValueConfigTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStatusValueConfig() {
        let config1 = StatusValueConfig()
        XCTAssertTrue(config1.get(4) == "In Work")
        XCTAssertTrue(config1.get("ca") == 8)
        let options = ("0 = Idea, 1 = Proposed, 2 = Approved, 3 = Planned, 4 = In Work, "
            + "5 = Hold, 6 = Done, 7 = Canceled, 8 = Closed, 9 = Archived")
        let config2 = StatusValueConfig(options)
        XCTAssertTrue(config2.get(9) == "Archived")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

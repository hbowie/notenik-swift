//
//  FieldLabelTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class FieldLabelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFieldLabel() {
        let fieldLabel = FieldLabel("Due Date")
        XCTAssertTrue(fieldLabel.commonForm == "duedate")
        fieldLabel.set("The Beatles")
        XCTAssertTrue(fieldLabel.commonForm == "beatles")
        fieldLabel.set("The 23rd Anniversary")
        XCTAssertTrue(fieldLabel.commonForm == "23rdanniversary")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

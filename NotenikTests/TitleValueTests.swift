//
//  TitleValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/3/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class TitleValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTitleValue() {
        let title1 = TitleValue("The Beatles")
        let title2 = TitleValue("beatles")
        XCTAssertTrue(title1 == title2)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

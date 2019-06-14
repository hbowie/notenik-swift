//
//  MarkedupTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 6/14/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import XCTest

class MarkedupTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func parseTest() {
        let markedup1 = Markedup(format: .htmlFragment)
        let text1 = "This isn't a **great** \"test\", but it's a _decent_ one."
        markedup1.parse(text: text1, startingLastCharWasWhiteSpace: true)
        print("Parsing result is: '\(markedup1)'")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

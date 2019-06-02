//
//  MergeScripterTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 5/31/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import XCTest

class MergeScripterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMergeScripterPlay() {
        let scripter = MergeScripter()
        scripter.play(scriptPath: "/Users/hbowie/Sites/notenik/reports/html-gen.tcz")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

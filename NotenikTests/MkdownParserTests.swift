//
//  MkdownParserTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 2/26/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import XCTest

class MkdownParserTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func parseTest() {
        let testURL = URL(fileURLWithPath: "/Users/hbowie/Xcode/Notenik/Test Collections/MkdownParserTest.md")
        let parser = MkdownParser(testURL)
        parser!.parse()
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        // self.measure {
            // Put the code you want to measure the time of here.
        // }
    }

}

//
//  StringConverterTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 6/10/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import XCTest

class StringConverterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConvert() {
        let xmlConverter = StringConverter()
        xmlConverter.addXML()
        XCTAssertTrue(xmlConverter.convert(from: "\"This is a test\"") == "&quot;This is a test&quot;")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

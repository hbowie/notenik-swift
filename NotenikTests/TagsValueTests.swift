//
//  TagsValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class TagsValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTagsValue() {
        let tags1 = TagsValue("Practopians.publish; For Herb")
        XCTAssertTrue(tags1.getTag(0)! == "For Herb")
        XCTAssertTrue(tags1.getLevel(tagIndex: 1, levelIndex: 1) == "publish")
        XCTAssertTrue(tags1.getTag(1)! == "Practopians.publish")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

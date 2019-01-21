//
//  LinkValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/3/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class LinkValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLinkValue() {
        let link1 = LinkValue("mailto:hbowie@mac.com")
        XCTAssertTrue(link1.getLinkPart1() == "mailto:")
        XCTAssertTrue(link1.getLinkPart2() == "hbowie@")
        XCTAssertTrue(link1.getLinkPart3() == "mac.com")
        XCTAssertTrue(link1.getLinkPart4() == "")
        XCTAssertTrue(link1.getLinkPart5() == "")
        
        link1.set("https://daringfireball.net/projects/")
        XCTAssertTrue(link1.getLinkPart1() == "https://")
        XCTAssertTrue(link1.getLinkPart2() == "")
        XCTAssertTrue(link1.getLinkPart3() == "daringfireball.net/")
        XCTAssertTrue(link1.getLinkPart4() == "projects")
        XCTAssertTrue(link1.getLinkPart5() == "/")
        
        link1.set("https://www.instapaper.com/read/1135183683")
        XCTAssertTrue(link1.getLinkPart1() == "https://")
        XCTAssertTrue(link1.getLinkPart2() == "www.")
        XCTAssertTrue(link1.getLinkPart3() == "instapaper.com/")
        XCTAssertTrue(link1.getLinkPart4() == "read/1135183683")
        XCTAssertTrue(link1.getLinkPart5() == "")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

//
//  FileNameTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/26/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class FileNameTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExt() {
        let fn1 = FileName("- readme.txt")
        XCTAssertEqual(fn1.ext, "txt")
        let fn2 = FileName("README.TXT")
        XCTAssertEqual(fn2.extLower, "txt")
    }
    
    func testBase() {
        let fn1 = FileName("- readme.txt")
        XCTAssertEqual(fn1.base, "- readme")
        XCTAssertTrue(fn1.readme)
        let fn2 = FileName("/Users/hbowie/Dropbox/Family/Stuff/iPhone.md")
        XCTAssertEqual(fn2.base, "iPhone")
        XCTAssertFalse(fn2.readme)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

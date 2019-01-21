//
//  BigStringReaderTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/9/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class BigStringReaderTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBigStringReader1() {
        let reader1 = BigStringReader()
        let bigString = "Line 1 " + "\n" + "Line 2" + "\r" + "Line 3"
        reader1.set(bigString)
        reader1.open()
        let line1 = reader1.readLine()
        print("Line 1 = " + line1!)
        XCTAssertTrue(line1 == "Line 1 ")
        let line2 = reader1.readLine()
        print("Line 2 = " + line2!)
        XCTAssertTrue(line2 == "Line 2")
        let line3 = reader1.readLine()
        print("Line 3 = " + line3!)
        XCTAssertTrue(line3 == "Line 3")
        let line4 = reader1.readLine()
        XCTAssertTrue(line4 == nil)
        reader1.close()
    }
    
    func testBigStringReader2() {

        let filePath = "/Users/hbowie/Dropbox/Family/Trips/2018-09 Chicago.md"
        var inString = ""
        do {
            inString = try String(contentsOfFile: filePath)
        } catch let error {
            print ("Failed reading from path : \(error)")
        }
        let reader2 = BigStringReader(inString)
        var line : String? = ""
        line = reader2.readLine()
        XCTAssertTrue(line == "Title:  2018-09 Chicago")
        line = reader2.readLine()
        XCTAssertTrue(line == "")
        line = reader2.readLine()
        XCTAssertTrue(line == "Date Added: 2018-04-08 13:31:50")
        print ("Printing line-by-line contents of " + filePath)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

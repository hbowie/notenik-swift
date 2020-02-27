//
//  LineParserTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/11/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class LineParserTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLineParser() {
        let filePath = "/Users/hbowie/Dropbox/Family/Trips/2018-09 Chicago.md"
        var inString = ""
        do {
            inString = try String(contentsOfFile: filePath)
        } catch let error {
            print ("Failed reading from path : \(error)")
        }
        let reader2 = BigStringReader(inString)
        let collection = NoteCollection()
        let parser = NoteLineParser(collection: collection, reader: reader2)
        let note1 = parser.getNote(defaultTitle: "2018-09 Chicago")
        XCTAssertTrue(note1.title.value == "2018-09 Chicago")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

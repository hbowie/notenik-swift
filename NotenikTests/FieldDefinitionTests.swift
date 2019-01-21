//
//  FieldDefinitionTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class FieldDefinitionTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFieldDefinition() {
        let def = FieldDefinition("Link")
        XCTAssertTrue(def.fieldType == FieldType.link)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

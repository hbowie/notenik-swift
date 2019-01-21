//
//  AuthorValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class AuthorValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAuthorValue() {
        let author1 = AuthorValue("Herb Bowie")
        XCTAssertTrue(author1.getCompleteName() == "Herb Bowie")
        XCTAssertTrue(author1.firstName == "Herb")
        XCTAssertTrue(author1.lastName == "Bowie")
        let author2 = AuthorValue("Herbert Hughes Bowie Jr.")
        XCTAssertTrue(author2.firstName == "Herbert Hughes")
        XCTAssertTrue(author2.lastName == "Bowie")
        XCTAssertTrue(author2.suffix == "Jr.")
        XCTAssertTrue(author2.lastNameFirst == "Bowie, Herbert Hughes Jr.")
        let author3 = AuthorValue("Bowie, Herbert Hughes Jr.")
        XCTAssertTrue(author3.firstName == "Herbert Hughes")
        XCTAssertTrue(author3.lastName == "Bowie")
        XCTAssertTrue(author3.suffix == "Jr.")
        XCTAssertTrue(author3.lastNameFirst == "Bowie, Herbert Hughes Jr.")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

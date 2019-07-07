//
//  SeqValueTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/6/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class SeqValueTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSeqValue() {
        let seq1 = SeqValue("a.1")
        seq1.increment(onLeft: false)
        XCTAssertTrue(seq1.value == "a.2")
        let seq2 = SeqValue("123.5")
        let pad2 = seq2.pad(leftChar: "0", leftNumber: 5, rightChar: "0", rightNumber: 2)
        XCTAssertEqual(pad2, "00123.50")
        let seq3 = SeqValue("9")
        seq3.increment(onLeft: true)
        XCTAssertEqual(seq3.value, "10")
        let seq4 = SeqValue("8")
        seq4.increment(onLeft: true)
        XCTAssertEqual(seq4.value, "9")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

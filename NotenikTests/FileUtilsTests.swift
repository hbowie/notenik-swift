//
//  FileUtilsTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/24/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class FileUtilsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsDir() {
        XCTAssertTrue(FileUtils.isDir("/Applications"))
        XCTAssertFalse(FileUtils.isDir("/Users/hbowie/Desktop/Adaptive Startup Log.txt"))
    }
    
    func testJoinPaths() {
        let path1 = FileUtils.joinPaths(path1: "/Users/hbowie/", path2: "/Dropbox")
        print ("Joined Path 1 = \(path1)")
        XCTAssertTrue(path1 == "/Users/hbowie/Dropbox")
        
        let path2 = FileUtils.joinPaths(path1: "/Users/hbowie", path2: "Dropbox")
        print ("Joined Path 2 = \(path2)")
        XCTAssertTrue(path2 == "/Users/hbowie/Dropbox")
        
        let path3 = FileUtils.joinPaths(path1: "/Users/hbowie/", path2: "Dropbox")
        print ("Joined Path 3 = \(path3)")
        XCTAssertTrue(path3 == "/Users/hbowie/Dropbox")
        
        let path4 = FileUtils.joinPaths(path1: "/Users/hbowie", path2: "/Dropbox")
        print ("Joined Path 4 = \(path4)")
        XCTAssertTrue(path4 == "/Users/hbowie/Dropbox")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

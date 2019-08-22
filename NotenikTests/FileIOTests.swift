//
//  FileIOTests.swift
//  NotenikTests
//
//  Created by Herb Bowie on 12/14/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import XCTest

class FileIOTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() {
        let io : NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        print ("Realm name = " + realm.name)
        print ("Realm path = " + realm.path)

    }
    
    func testOpenCollection() {
        let io : NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.name = "Herb Bowie"
        realm.path = "/Users/hbowie/"
        let collection : NoteCollection? = io.openCollection(realm: realm, collectionPath: "Dropbox/Family/Stuff")
        if collection == nil {
            print ("Problems opening collection!")
        } else {
            var note     : Note?
            var position : NotePosition
            (note, position) = io.firstNote()
            while position.index >= 0 {
                print ("Note # \(position.index) = \(note!.title)")
                (note, position) = io.nextNote(position)
            }
        }
    }
    
    func testSortParm() {
        let io : NotenikIO = FileIO()
        let realm = io.getDefaultRealm()
        realm.name = "Herb Bowie"
        realm.path = "/Users/hbowie/"
        let collection : NoteCollection? = io.openCollection(realm: realm,
                                            collectionPath: "Library/Mobile Documents/com~apple~CloudDocs/Notenik/iWisdom")
        if collection == nil {
            print ("Problems opening collection!")
        } else {
            var note     : Note?
            var position : NotePosition
            (note, position) = io.firstNote()
            while position.index >= 0 {
                print ("Note # \(position.index) = \(note!.title)")
                print ("Sort Key = \(note!.sortKey)")
                (note, position) = io.nextNote(position)
            }
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

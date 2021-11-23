//
//  NewFromKlassViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/12/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class NewFromKlassViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var window: NewFromClassWindowController?

    @IBOutlet var klassComboBox: NSComboBox!
    @IBOutlet var collectionPath: NSPathControl!
    
    @IBOutlet var errorMsg: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorMsg.stringValue = ""
    }
    
    var noteIO: NotenikIO? {
        get {
            return io
        }
        set {
            io = newValue
            collection = io?.collection
            if collection != nil {
                klassComboBox.removeAllItems()
                for klassDef in collection!.klassDefs {
                    klassComboBox.addItem(withObjectValue: klassDef.name)
                }
                if collection!.lastNewKlass.isEmpty {
                    klassComboBox.selectItem(at: 0)
                } else {
                    klassComboBox.stringValue = collection!.lastNewKlass
                }
                collectionPath.url = collection!.fullPathURL
            }
        }
    }
    var io: NotenikIO?
    var collection: NoteCollection?
    
    var collectionWC: CollectionWindowController?
    
    @IBAction func proceed(_ sender: Any) {
        guard collectionWC != nil else { return }
        guard let klassDefs = collection?.klassDefs else { return }
        let selected = klassComboBox.stringValue
        guard !selected.isEmpty else {
            errorMsg.stringValue = "No Class Specified"
            return
        }
        var defFound = false
        for klassDef in klassDefs {
            if selected == klassDef.name {
                collection!.lastNewKlass = selected
                collectionWC!.newNote(klassDef: klassDef)
                defFound = true
                break
            }
        }
        if !defFound {
            errorMsg.stringValue = "Cannot find a Template for the Specified Class Name"
            return
        } else {
            application.stopModal(withCode: .OK)
            window!.close()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        window!.close()
    }
    
}

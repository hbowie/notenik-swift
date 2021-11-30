//
//  NewWithOptionsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/12/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class NewWithOptionsViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var window: NewWithOptionsWindowController?
    
    var io: NotenikIO?
    var collection: NoteCollection?
    var levelConfig = IntWithLabelConfig()
    
    var collectionWC: CollectionWindowController?
    
    var currKlass: KlassValue?
    var currLevel: LevelValue?
    var currSeq:   SeqValue?

    @IBOutlet var titleField: NSTextField!
    @IBOutlet var klassComboBox: NSComboBox!
    @IBOutlet var levelPopup: NSPopUpButton!
    @IBOutlet var collectionPath: NSPathControl!
    @IBOutlet var seqField: NSTextField!
    
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
                
                // Set up collection path, to provide context for user.
                collectionPath.url = collection!.fullPathURL
                
                // Set up Class Combo Box
                klassComboBox.removeAllItems()
                if collection!.klassDefs.count == 0 {
                    klassComboBox.stringValue = ""
                    klassComboBox.isEnabled = false
                } else {
                    klassComboBox.isEnabled = true
                    for klassDef in collection!.klassDefs {
                        klassComboBox.addItem(withObjectValue: klassDef.name)
                    }
                    if collection!.lastNewKlass.isEmpty {
                        klassComboBox.selectItem(at: 0)
                    } else {
                        klassComboBox.stringValue = collection!.lastNewKlass
                    }
                }
                
                // Set up Level Popup Menu
                levelPopup.removeAllItems()
                levelConfig = collection!.levelConfig
                if collection!.levelFieldDef == nil {
                    levelPopup.isEnabled = false
                } else {
                    levelPopup.isEnabled = true
                    for index in levelConfig.low...levelConfig.high {
                        let intWithLabel = levelConfig.intWithLabel(forInt: index)
                        levelPopup.addItem(withTitle: intWithLabel)
                        // let menuItem = menu.item(at: menu.numberOfItems - 1)
                        // menuItem!.attributedTitle = AppPrefsCocoa.shared.makeUserAttributedString(text: intWithLabel)
                    }
                }
                
                // Set up Seq field
                seqField.stringValue = ""
                if collection!.seqFieldDef == nil {
                    seqField.isEnabled = false
                } else {
                    seqField.isEnabled = true
                }
            }
        }
    }
    
    func setCurrentNote(_ note: Note) {
        print("setCurrentNote to Note titled \(note.title.value)")
        currKlass = note.klass
        if !currKlass!.value.isEmpty {
            klassComboBox.stringValue = currKlass!.value
        }
        currLevel = note.level
        let currLevelInt = currLevel!.getInt()
        if currLevelInt > 0 && currLevelInt <= levelPopup.numberOfItems {
            levelPopup.selectItem(at: currLevelInt - 1)
        }
        currSeq = note.seq
        
        print("  - Class = \(currKlass!.value)")
        print("  - Level = \(currLevel!.value)")
        print("  - Seq = \(currSeq!.value)")
        
        adjustSeq()
    }

    
    @IBAction func levelSelected(_ sender: Any) {
        print("Level Selected, index = \(levelPopup.indexOfSelectedItem), value = \(levelPopup.stringValue)")
        adjustSeq()
    }
    
    @IBAction func increaseLevel(_ sender: Any) {
        let currLevel = levelPopup.indexOfSelectedItem
        let newLevel = currLevel + 1
        if newLevel < levelPopup.numberOfItems {
            levelPopup.selectItem(at: newLevel)
        }
        adjustSeq()
    }
    
    @IBAction func decreaseLevel(_ sender: Any) {
        let currLevel = levelPopup.indexOfSelectedItem
        let newLevel = currLevel - 1
        if newLevel < levelPopup.numberOfItems && newLevel >= 0 {
            levelPopup.selectItem(at: newLevel)
        }
        adjustSeq()
    }
    
    func adjustSeq() {
        let newSeq = SeqValue(currSeq!.value)
        let newLevelInt = levelPopup.indexOfSelectedItem + 1
        let newLevel = LevelValue(i: newLevelInt,
                                  config: collection!.levelConfig)

        if newLevel > currLevel! {
            newSeq.newChild()
        } else if newLevel < currLevel! {
            newSeq.dropLevelAndInc()
        } else {
            newSeq.increment()
        }
        seqField.stringValue = newSeq.value
    }
    
    @IBAction func proceed(_ sender: Any) {
        guard collectionWC != nil else { return }
        collectionWC!.newNote(title: titleField.stringValue,
                              bodyText: nil,
                              klassName: klassComboBox.stringValue,
                              level: levelPopup.titleOfSelectedItem,
                              seq: seqField.stringValue)

        application.stopModal(withCode: .OK)
        window!.close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        window!.close()
    }
    
}

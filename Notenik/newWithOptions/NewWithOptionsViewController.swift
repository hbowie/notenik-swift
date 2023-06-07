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
            
            klassComboBox.removeAllItems()
            klassComboBox.stringValue = ""
            klassComboBox.isEnabled = false
            
            levelPopup.removeAllItems()
            levelPopup.isEnabled = false
            
            seqField.stringValue = ""
            seqField.isEnabled = false
            
            guard let collection = io?.collection else { return }
            self.collection = collection

            // Set up collection path, to provide context for user.
            collectionPath.url = collection.fullPathURL
            
            // Set up Class Combo Box
            if let def = collection.klassFieldDef {
                if let pickList = def.pickList as? KlassPickList {
                    klassComboBox.isEnabled = true
                    for value in pickList.values {
                        klassComboBox.addItem(withObjectValue: value.value)
                    }
                } else if collection.klassDefs.count > 0 {
                    klassComboBox.isEnabled = true
                    for klassDef in collection.klassDefs {
                        klassComboBox.addItem(withObjectValue: klassDef.name)
                    }
                }
                if collection.lastNewKlass.isEmpty {
                    klassComboBox.selectItem(at: 0)
                } else {
                    klassComboBox.stringValue = collection.lastNewKlass
                }
            }
            
            // Set up Level Popup Menu
            levelConfig = collection.levelConfig
            if collection.levelFieldDef != nil {
                levelPopup.isEnabled = true
                for index in levelConfig.low...levelConfig.high {
                    let intWithLabel = levelConfig.intWithLabel(forInt: index)
                    levelPopup.addItem(withTitle: intWithLabel)
                }
            }
            
            // Set up Seq field
            if collection.seqFieldDef != nil {
                seqField.isEnabled = true
            }
        }
    }
    
    func setCurrentNote(_ note: Note) {
        currKlass = note.klass
        if !currKlass!.value.isEmpty {
            klassComboBox.stringValue = currKlass!.value
        }
        currLevel = note.level
        let currLevelInt = currLevel!.getInt()
        let levelIndex = currLevelInt - levelConfig.low
        if levelIndex >= 0 && levelIndex < levelPopup.numberOfItems {
            levelPopup.selectItem(at: levelIndex)
        }
        currSeq = note.seq
        
        adjustSeq()
    }

    
    @IBAction func levelSelected(_ sender: Any) {
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
        guard collection != nil else { return }
        guard let newSeq = currSeq?.dupe() else { return }
        let newLevelInt = levelPopup.indexOfSelectedItem + levelConfig.low
        let newLevel = LevelValue(i: newLevelInt,
                                  config: collection!.levelConfig)
        newSeq.incByLevels(originalLevel: currLevel!, newLevel: newLevel)
        seqField.stringValue = newSeq.value
    }
    
    @IBAction func proceed(_ sender: Any) {
        guard collectionWC != nil else { return }
        collectionWC!.newNote(title: titleField.stringValue,
                              bodyText: nil,
                              klassName: klassComboBox.stringValue,
                              level: levelPopup.titleOfSelectedItem,
                              seq: seqField.stringValue,
                              addAndReturn: false)

        application.stopModal(withCode: .OK)
        window!.close()
    }
    
    @IBAction func addAndReturn(_ sender: Any) {
        guard collectionWC != nil else { return }
        application.stopModal(withCode: .OK)
        window!.close()
        collectionWC!.newNote(title: titleField.stringValue,
                              bodyText: nil,
                              klassName: klassComboBox.stringValue,
                              level: levelPopup.titleOfSelectedItem,
                              seq: seqField.stringValue,
                              addAndReturn: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        window!.close()
    }
    
}

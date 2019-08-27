//
//  ScriptViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Controls the Scripter View. 
class ScriptViewController: NSViewController {
    
    var window: ScriptWindowController!
    
    var scripter = ScriptEngine()

    @IBOutlet var parentView:     NSView!
    @IBOutlet var gridView: NSGridView!
    @IBOutlet var scrollingTextView: NSScrollView!
    
    @IBOutlet var modulePopUp:    NSPopUpButton!
    @IBOutlet var actionPopUp:    NSPopUpButton!
    @IBOutlet var modifierPopUp:  NSPopUpButton!
    @IBOutlet var objectComboBox: NSComboBox!
    @IBOutlet var valueText:      NSTextField!
    
    var command = ScriptCommand()
    
    @IBOutlet var scriptLog:   NSTextView!
    
    func scriptOpenInput(_ scriptURL: URL) {
        scripter = ScriptEngine()
        let command = scripter.getCommand(moduleStr: "script")!
        command.action = .open
        command.modifier = "input"
        command.setValue(fileURL: scriptURL)
        scripter.playCommand(command)
        updateLogView()
        
        modulePopUp.selectItem(at: 0)
        modulePopUpSelected(self)
        actionPopUp.selectItem(at: 1)
        actionPopUpSelected(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // AppPrefs.shared.setRegularFont(object: scriptPath)
        
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        gridView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        gridView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        //gridView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
        
        scrollingTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollingTextView.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 8).isActive = true
        scrollingTextView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        scrollingTextView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        scrollingTextView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
        AppPrefs.shared.setRegularFont(object: scriptLog)
        
        modulePopUp.removeAllItems()
        modulePopUp.addItem(withTitle: "script")
        modulePopUp.addItem(withTitle: "input")
        modulePopUp.addItem(withTitle: "filter")
        modulePopUp.addItem(withTitle: "sort")
        modulePopUp.addItem(withTitle: "template")
        modulePopUp.addItem(withTitle: "output")
        modulePopUp.selectItem(at: 0)
        
        modulePopUpSelected(self)
    }
    

    
    @IBAction func modulePopUpSelected(_ sender: Any) {
        command = scripter.getCommand(moduleStr: modulePopUp.titleOfSelectedItem!)!
        setActionOptions()
    }
    
    func setActionOptions() {
        actionPopUp.removeAllItems()
        switch command.module {
        case .script:
            actionPopUp.addItem(withTitle: "open")
            actionPopUp.addItem(withTitle: "play")
            actionPopUp.addItem(withTitle: "record")
            actionPopUp.addItem(withTitle: "stop")
        case .input:
            actionPopUp.addItem(withTitle: "set")
            actionPopUp.addItem(withTitle: "open")
        case .filter, .sort:
            actionPopUp.addItem(withTitle: "clear")
            actionPopUp.addItem(withTitle: "add")
            actionPopUp.addItem(withTitle: "set")
        case .template:
            actionPopUp.addItem(withTitle: "webroot")
            actionPopUp.addItem(withTitle: "open")
            actionPopUp.addItem(withTitle: "generate")
        case .output:
            actionPopUp.addItem(withTitle: "open")
        default:
            actionPopUp.addItem(withTitle: " ")
        }
        actionPopUp.selectItem(at: 0)
        actionPopUpSelected(self)
    }
    
    @IBAction func actionPopUpSelected(_ sender: Any) {
        command.setAction(value: actionPopUp.titleOfSelectedItem!)
        setModifierOptions()
    }
    
    func setModifierOptions() {
        modifierPopUp.removeAllItems()
        if command.module == .script && command.action == .open {
            modifierPopUp.addItem(withTitle: "input")
            modifierPopUp.addItem(withTitle: "output")
        } else if command.module == .input && command.action == .open {
            modifierPopUp.addItem(withTitle: "dir")
            modifierPopUp.addItem(withTitle: "file")
            modifierPopUp.addItem(withTitle: "notenik-defined")
            modifierPopUp.addItem(withTitle: "notenik+")
            modifierPopUp.addItem(withTitle: "notenik-general")
            modifierPopUp.addItem(withTitle: "notenik-index")
            modifierPopUp.addItem(withTitle: "xlsx")
        } else if command.module == .filter && command.action == .add {
            modifierPopUp.addItem(withTitle: "eq")
            modifierPopUp.addItem(withTitle: "gt")
            modifierPopUp.addItem(withTitle: "ge")
            modifierPopUp.addItem(withTitle: "lt")
            modifierPopUp.addItem(withTitle: "le")
            modifierPopUp.addItem(withTitle: "ne")
            modifierPopUp.addItem(withTitle: "co")
            modifierPopUp.addItem(withTitle: "nc")
            modifierPopUp.addItem(withTitle: "st")
            modifierPopUp.addItem(withTitle: "ns")
            modifierPopUp.addItem(withTitle: "fi")
            modifierPopUp.addItem(withTitle: "nf")
        } else if command.module == .sort && command.action == .add {
            modifierPopUp.addItem(withTitle: "ascending")
            modifierPopUp.addItem(withTitle: "descending")
        } else {
            modifierPopUp.addItem(withTitle: " ")
        }
        modifierPopUp.selectItem(at: 0)
        modifierPopUpSelected(self)
    }
    
    @IBAction func modifierPopUpSelected(_ sender: Any) {
        command.modifier = modifierPopUp.titleOfSelectedItem!
        setObjectOptions()
    }
    
    func setObjectOptions() {
        objectComboBox.removeAllItems()
        objectComboBox.stringValue = ""
        if command.module == .input && command.action == .set {
            objectComboBox.addItem(withObjectValue: "xpltags")
            objectComboBox.addItem(withObjectValue: "dirdepth")
        } else if command.module == .input && command.action == .open {
            objectComboBox.addItem(withObjectValue: " ")
            objectComboBox.addItem(withObjectValue: "merge")
        } else if ((command.module == .filter && command.action == .add)
            || (command.module == .sort && command.action == .add)) {
            loadFieldNames()
        }
        if objectComboBox.numberOfItems == 0 {
            objectComboBox.addItem(withObjectValue: " ")
        }
        objectComboBox.selectItem(at: 0)
    }
    
    func loadFieldNames() {
        let workspace = scripter.workspace
        let collection = workspace.collection
        let dict = collection.dict
        for fieldDef in dict.list {
            let fieldName = fieldDef.fieldLabel.properForm
            objectComboBox.addItem(withObjectValue: fieldName)
        }
    }
    
    @IBAction func objectComboBoxSelected(_ sender: Any) {
        command.object = objectComboBox.stringValue
        valueText.stringValue = ""
    }
    
    @IBAction func selectFileAction(_ sender: Any) {
        if (command.module == .script && command.action == .open && command.modifier == "output")
            || (command.module == .output && command.action == .open) {
            let savePanel = NSSavePanel();
            savePanel.title = "Specify an output file"
            savePanel.directoryURL = scripter.workspace.parentURL
            savePanel.showsResizeIndicator = true
            savePanel.showsHiddenFiles = false
            savePanel.canCreateDirectories = true
            if command.module == .script {
                savePanel.allowedFileTypes = ["tcz"]
                savePanel.allowsOtherFileTypes = false
            } else {
                savePanel.allowedFileTypes = ["txt", "csv", "tab"]
                savePanel.allowsOtherFileTypes = true
            }
            let userChoice = savePanel.runModal()
            if userChoice == .OK {
                command.setValue(fileURL: savePanel.url!)
                valueText.stringValue = command.value
            }
        } else {
            let openPanel = NSOpenPanel();
            openPanel.title = "Open an input file"
            openPanel.directoryURL = scripter.workspace.parentURL
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            let userChoice = openPanel.runModal()
            if userChoice == .OK {
                command.setValue(fileURL: openPanel.url!)
                valueText.stringValue = command.value
            }
        }
    }
    
    @IBAction func plusAction(_ sender: Any) {
        command = scripter.getCommand(moduleStr: modulePopUp.titleOfSelectedItem!)!
        command.setAction(value: actionPopUp.titleOfSelectedItem!)
        command.modifier = modifierPopUp.titleOfSelectedItem!
        command.object = objectComboBox.stringValue
        command.value = valueText.stringValue
        scripter.playCommand(command)
        updateLogView()
    }
    
    func updateLogView() {
        scriptLog.string = scripter.workspace.scriptLog
    }
    
}

//
//  ScriptViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

/// Controls the Scripter View. 
class ScriptViewController: NSViewController {
    
    var juggler = CollectionJuggler.shared
    
    var window: ScriptWindowController!
    
    var scripter = ScriptEngine()
    
    var dispatchQ = DispatchQueue(label: "com.powersurgepub.notenik.script.queue",
                                  qos: .userInitiated)

    @IBOutlet var parentView:     NSView!
    @IBOutlet var gridView: NSGridView!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var scrollingTextView: NSScrollView!
    
    @IBOutlet var modulePopUp:    NSPopUpButton!
    @IBOutlet var actionPopUp:    NSPopUpButton!
    @IBOutlet var modifierPopUp:  NSPopUpButton!
    @IBOutlet var objectComboBox: NSComboBox!
    @IBOutlet var valueComboBox:  NSComboBox!
    
    var pathNeededForValue = false
    
    var command = ScriptCommand()
    
    @IBOutlet var scriptLog:   NSTextView!
    
    func scriptOpenInput(_ scriptURL: URL, goNow: Bool = false) {
        scripter = ScriptEngine()
        let command = scripter.getCommand(moduleStr: "script")!
        command.action = .open
        command.modifier = "input"
        command.setValue(fileURL: scriptURL)
        juggler.lastScript = scriptURL
        scripter.playCommand(command)
        updateLogView(workspace: scripter.workspace)
        
        modulePopUp.selectItem(at: 0)
        modulePopUpSelected(self)
        actionPopUp.selectItem(at: 1)
        actionPopUpSelected(self)
        
        if goNow {
            goAction(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        gridView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        gridView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 8).isActive = true
        progressIndicator.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        progressIndicator.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        
        scrollingTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollingTextView.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 8).isActive = true
        scrollingTextView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        scrollingTextView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        scrollingTextView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
        AppPrefsCocoa.shared.setTextEditingFont(object: scriptLog)
        
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
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        scripter.close()
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
            actionPopUp.addItem(withTitle: "")
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
            modifierPopUp.addItem(withTitle: "markdown-with-headers")
            modifierPopUp.addItem(withTitle: "notenik-defined")
            modifierPopUp.addItem(withTitle: "notenik+")
            modifierPopUp.addItem(withTitle: "notenik-general")
            modifierPopUp.addItem(withTitle: "notenik-index")
            modifierPopUp.addItem(withTitle: "notenik-split-tags")
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
            modifierPopUp.addItem(withTitle: "")
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
            objectComboBox.addItem(withObjectValue: "")
            objectComboBox.addItem(withObjectValue: "merge")
        } else if ((command.module == .filter && command.action == .add)
            || (command.module == .sort && command.action == .add)) {
            loadFieldNames()
        } else if command.action == .set
            && (command.module == .filter || command.module == .sort) {
            objectComboBox.addItem(withObjectValue: "params")
        }
        if objectComboBox.numberOfItems == 0 {
            objectComboBox.addItem(withObjectValue: "")
        }
        objectComboBox.selectItem(at: 0)
        objectComboBoxSelected(self)
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
        setValueOptions()
    }
    
    func setValueOptions() {
        valueComboBox.removeAllItems()
        pathNeededForValue = false
        if command.module == .input && command.action == .set {
            if command.object == "xpltags" {
                valueComboBox.addItem(withObjectValue: "false")
                valueComboBox.addItem(withObjectValue: "true")
            } else if command.object == "dirdepth" {
                valueComboBox.addItem(withObjectValue: "1")
                valueComboBox.addItem(withObjectValue: "2")
                valueComboBox.addItem(withObjectValue: "3")
                valueComboBox.addItem(withObjectValue: "4")
                valueComboBox.addItem(withObjectValue: "5")
                valueComboBox.addItem(withObjectValue: "6")
                valueComboBox.addItem(withObjectValue: "7")
                valueComboBox.addItem(withObjectValue: "8")
                valueComboBox.addItem(withObjectValue: "9")
                valueComboBox.addItem(withObjectValue: "10")
            }
        } else if command.action == .open {
            pathNeededForValue = true
        }
        if valueComboBox.numberOfItems == 0 {
            valueComboBox.addItem(withObjectValue: "")
        }
        valueComboBox.selectItem(at: 0)
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
                valueComboBox.stringValue = command.value
            }
        } else {
            let openPanel = NSOpenPanel();
            openPanel.title = "Open an input file"
            openPanel.directoryURL = scripter.workspace.parentURL
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            if command.modifier == "dir" || command.modifier.hasPrefix("notenik")
                    || (command.module == .template && command.action == .webroot) {
                openPanel.canChooseFiles = false
                openPanel.canChooseDirectories = true
            } else {
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
            }
            openPanel.canCreateDirectories = false
            openPanel.allowsMultipleSelection = false
            let userChoice = openPanel.runModal()
            if userChoice == .OK {
                command.setValue(fileURL: openPanel.url!)
                valueComboBox.stringValue = command.value
            } else {
                command.value = ""
                valueComboBox.stringValue = ""
            }
        }
    }
    
    @IBAction func valueComboBoxSelected(_ sender: Any) {
    }
    
    @IBAction func goAction(_ sender: Any) {
        if pathNeededForValue &&
            (valueComboBox.stringValue == "" || valueComboBox.stringValue == " ") {
            selectFileAction(sender)
        }
        command = scripter.getCommand(moduleStr: modulePopUp.titleOfSelectedItem!)!
        command.setAction(value: actionPopUp.titleOfSelectedItem!)
        command.modifier = modifierPopUp.titleOfSelectedItem!
        command.object = objectComboBox.stringValue
        command.value = valueComboBox.stringValue
        
        if command.module == .script
            && command.action == .play
            && scripter.workspace.scriptURL != nil {
            dispatchScriptPlayer(scriptURL: scripter.workspace.scriptURL!)
        } else {
            scripter.playCommand(command)
        }
        
        updateLogView(workspace: scripter.workspace)
        if command.module == .script {
            if command.action == .open {
                if command.modifier == "input" {
                    actionPopUp.selectItem(at: 1)
                    actionPopUpSelected(sender)
                } else if command.modifier == "output" {
                    actionPopUp.selectItem(at: 2)
                    actionPopUpSelected(sender)
                }
            }
        }
    }
    
    func dispatchScriptPlayer(scriptURL: URL) {
        let player = ScriptPlayer()
        let fileName = scriptURL.path
        progressIndicator.startAnimation(self)
        player.scripter.workspace.writeLineToLog("Asynchronous Script Execution Starting...")
        updateLogView(workspace: player.scripter.workspace)
        logInfo(msg: "Asynchronous Script Execution Starting...")
        dispatchQ.async { [weak self] in
            player.playScript(fileName: fileName)
            DispatchQueue.main.async { [weak self] in
                player.scripter.workspace.writeLineToLog("Asynchronous Script Execution Ended.")
                self?.updateLogView(workspace: player.scripter.workspace)
                self?.logInfo(msg: "Script Execution Completed")
                self?.progressIndicator.stopAnimation(self)
                CollectionJuggler.shared.showScriptWindow()
            }
        }
    }
    
    func updateLogView(workspace: ScriptWorkspace) {
        scriptLog.string = workspace.scriptLog
    }
    
    func logInfo(msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "ScriptViewController",
                          level: .info,
                          message: msg)
    }
    
}

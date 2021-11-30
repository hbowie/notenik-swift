//
//  CollectionPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

import NotenikLib

class CollectionPrefsViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var collection: NoteCollection?
    var windowController: CollectionPrefsWindowController?
    var defsRemoved = DefsRemoved()
    
    @IBOutlet var collectionTitle:      NSTextField!
    @IBOutlet var fileExtComboBox:      NSComboBox!
    @IBOutlet var collectionShortcut:   NSTextField!
    @IBOutlet var mirrorAutoIndexCkBox: NSButton!
    @IBOutlet var bodyLabelCkBox:       NSButton!
    @IBOutlet var h1TitlesCkBox:        NSButton!
    @IBOutlet var streamlinedCkBox:     NSButton!
    @IBOutlet var mathJaxCkBox:         NSButton!
    @IBOutlet var pathControl:          NSPathControl!
    @IBOutlet var parentView:           NSView!
    
    var extPicker: FileExtensionPicker!
    
    @IBOutlet var horizontalStack: NSStackView!
    
    var stackView: NSStackView!
    
    var fieldsLabel:     NSTextField!
    
    var fieldSelectors:  [NSButton] = []
    
    var titleCkBox:      NSButton!
    var akaCkBox:        NSButton!
    var timestampCkBox:  NSButton!
    var tagsCkBox:       NSButton!
    var linkCkBox:       NSButton!
    var statusCkBox:     NSButton!
    var typeCkBox:       NSButton!
    var seqCkBox:        NSButton!
    var levelCkBox:      NSButton!
    var klassCkBox:      NSButton!
    var dateCkBox:       NSButton!
    var recursCkBox:     NSButton!
    var authorCkBox:     NSButton!
    var attribCkBox:     NSButton!
    var ratingCkBox:     NSButton!
    var indexCkBox:      NSButton!
    var codeCkBox:       NSButton!
    var teaserCkBox:     NSButton!
    var bodyCkBox:       NSButton!
    var dateAddedCkBox:  NSButton!
    var dateModifiedCkBox: NSButton!
    var backlinksCkBox:  NSButton!
    
    var otherFieldsCkBox: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extPicker = FileExtensionPicker(fileExtComboBox: fileExtComboBox)
        makeViews()
    }
    
    /// Create the fields we need.
    func makeViews() {
        collectionTitle.maximumNumberOfLines = 3
        // makeStackViews()
    }
    
    /// Pass needed info from the Collection Juggler
    func passCollectionPrefsRequesterInfo(
                         collection: NoteCollection,
                         window: CollectionPrefsWindowController,
                         defsRemoved: DefsRemoved) {
        
        self.collection = collection
        self.windowController = window
        self.defsRemoved = defsRemoved
        setCollectionValues()
        makeStackViews()

        let collectionFileName = FileName(collection.fullPath)
        pathControl.url = collection.fullPathURL
        
        // The following nonsense attempts to work around a bug
        // that truncates part of the last folder name if it
        // contains a space. 
        var i = collectionFileName.folders.count - 1
        var j = pathControl.pathItems.count - 1
        while i >= 0 && j > 0 {
            let pathItem = pathControl.pathItems[j]
            pathItem.title = collectionFileName.folders[i]
            i -= 1
            j -= 1
        }
    }
    
    func setCollectionValues() {
        guard collection != nil else { return }
        
        if collectionTitle != nil {
            collectionTitle!.stringValue = collection!.title
        }
        
        if collectionShortcut != nil {
            collectionShortcut!.stringValue = collection!.shortcut
        }
        
        extPicker.setFileExt(collection!.preferredExt)
        setMirrorAutoIndex(collection!.mirrorAutoIndex)
        setBodyLabel(collection!.bodyLabel)
        setH1Titles(collection!.h1Titles)
        setStreamlined(collection!.streamlined)
        setMathJax(collection!.mathJax)
    }
    
    func makeStackViews() {
        
        // Make sure our containers are empty
        // before we start to fill them.
        while horizontalStack.arrangedSubviews.count > 0 {
            let view = horizontalStack.arrangedSubviews[0]
            horizontalStack.removeArrangedSubview(view)
        }
        fieldSelectors = []
        
        // Start our first vertical stack.
        startNextVerticalStack()
        
        titleCkBox = NSButton(checkboxWithTitle: NotenikConstants.title, target: self, action: #selector(checkBoxClicked))
        addToStack(titleCkBox)
        
        akaCkBox = NSButton(checkboxWithTitle: NotenikConstants.aka, target: self, action: #selector(checkBoxClicked))
        addToStack(akaCkBox)
        
        timestampCkBox = NSButton(checkboxWithTitle: NotenikConstants.timestamp, target: self, action: #selector(checkBoxClicked))
        addToStack(timestampCkBox)
        
        tagsCkBox = NSButton(checkboxWithTitle: NotenikConstants.tags, target: self, action: #selector(checkBoxClicked))
        addToStack(tagsCkBox)
        
        linkCkBox = NSButton(checkboxWithTitle: NotenikConstants.link, target: self, action: #selector(checkBoxClicked))
        addToStack(linkCkBox)
        
        statusCkBox = NSButton(checkboxWithTitle: NotenikConstants.status, target: self, action: #selector(checkBoxClicked))
        addToStack(statusCkBox)
        
        typeCkBox = NSButton(checkboxWithTitle: NotenikConstants.type, target: self, action: #selector(checkBoxClicked))
        addToStack(typeCkBox)
        
        seqCkBox = NSButton(checkboxWithTitle: NotenikConstants.seq, target: self, action: #selector(checkBoxClicked))
        addToStack(seqCkBox)
        
        levelCkBox = NSButton(checkboxWithTitle: NotenikConstants.level, target: self, action: #selector(checkBoxClicked))
        addToStack(levelCkBox)
        
        klassCkBox = NSButton(checkboxWithTitle: NotenikConstants.klass, target: self, action: #selector(checkBoxClicked))
        addToStack(klassCkBox)
        
        dateCkBox = NSButton(checkboxWithTitle: NotenikConstants.date, target: self, action: #selector(checkBoxClicked))
        addToStack(dateCkBox)
        
        recursCkBox = NSButton(checkboxWithTitle: NotenikConstants.recurs, target: self, action: #selector(checkBoxClicked))
        addToStack(recursCkBox)
        
        authorCkBox = NSButton(checkboxWithTitle: NotenikConstants.author, target: self, action: #selector(checkBoxClicked))
        addToStack(authorCkBox)
        
        attribCkBox = NSButton(checkboxWithTitle: NotenikConstants.attribution, target: self, action: #selector(checkBoxClicked))
        addToStack(attribCkBox)
        
        ratingCkBox = NSButton(checkboxWithTitle: NotenikConstants.rating, target: self, action: #selector(checkBoxClicked))
        addToStack(ratingCkBox)
        
        indexCkBox = NSButton(checkboxWithTitle: NotenikConstants.index, target: self, action: #selector(checkBoxClicked))
        addToStack(indexCkBox)
        
        codeCkBox = NSButton(checkboxWithTitle: NotenikConstants.code, target: self, action: #selector(checkBoxClicked))
        addToStack(codeCkBox)
        
        teaserCkBox = NSButton(checkboxWithTitle: NotenikConstants.teaser, target: self, action: #selector(checkBoxClicked))
        addToStack(teaserCkBox)
        
        dateAddedCkBox = NSButton(checkboxWithTitle: NotenikConstants.dateAdded, target: self, action: #selector(checkBoxClicked))
        addToStack(dateAddedCkBox)
        
        dateModifiedCkBox = NSButton(checkboxWithTitle: NotenikConstants.dateModified, target: self, action: #selector(checkBoxClicked))
        addToStack(dateModifiedCkBox)
        
        backlinksCkBox = NSButton(checkboxWithTitle: NotenikConstants.backlinks,
                                  target: self,
                                  action: #selector(checkBoxClicked))
        addToStack(backlinksCkBox)
        
        bodyCkBox = NSButton(checkboxWithTitle: NotenikConstants.body, target: self, action: #selector(checkBoxClicked))
        addToStack(bodyCkBox)
        
        // checkBoxInsertionPoint = stackView.arrangedSubviews.count - 1
        setFieldsForCollection()
        
        otherFieldsCkBox = NSButton(checkboxWithTitle: "Other fields allowed?", target: self, action: #selector(checkBoxClicked))
        addToStack(otherFieldsCkBox, fieldSelector: false)
        
        setOtherFieldsAllowed(collection!.otherFields)

        finishNextVerticalStack()
        
    }
    
    func addToStack(_ checkbox: NSButton, fieldSelector: Bool = true) {
        if fieldSelector {
            fieldSelectors.append(checkbox)
        }
        stackView.addArrangedSubview(checkbox)
        if stackView.arrangedSubviews.count >= 15 {
            finishNextVerticalStack()
            startNextVerticalStack()
        }
    }
    
    func startNextVerticalStack() {
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
    }
    
    func finishNextVerticalStack() {
        guard stackView.arrangedSubviews.count > 0 else { return }
        horizontalStack.addArrangedSubview(stackView)
    }
    
    func setFieldsForCollection() {
        
        guard collection != nil else { return }
        
        // Start by turning all the check boxes off
        for button in fieldSelectors {
            button.state = NSControl.StateValue.off
        }
        
        let dict = collection!.dict
        let defs = dict.list
        for def in defs {
            var i = 0
            var looking = true
            while i < fieldSelectors.count && looking {
                let button = fieldSelectors[i]
                if def.fieldLabel.properForm == button.title {
                    looking = false
                    button.state = NSControl.StateValue.on
                } else {
                    i += 1
                }
            } // End inner loop going through Check Box controls
            if looking {
                let newCheckBox = NSButton(checkboxWithTitle: def.fieldLabel.properForm, target: self, action: #selector(checkBoxClicked))
                newCheckBox.state = NSControl.StateValue.on
                addToStack(newCheckBox)
                // fieldSelectors.append(newCheckBox)
                // stackView.insertArrangedSubview(newCheckBox, at: checkBoxInsertionPoint)
                // checkBoxInsertionPoint += 1
            }
        } // End outer loop, going through all existing field definitions
        
        titleCkBox.isEnabled = false
        bodyCkBox.isEnabled = false
    }
    
    func setOtherFieldsAllowed(_ allowed: Bool) {
        if allowed {
            otherFieldsCkBox.state = .on
        } else {
            otherFieldsCkBox.state = .off
        }
    }
    
    func setMirrorAutoIndex(_ on: Bool) {
        if on {
            mirrorAutoIndexCkBox.state = .on
        } else {
            mirrorAutoIndexCkBox.state = .off
        }
    }
    
    func setBodyLabel(_ on: Bool) {
        if on {
            bodyLabelCkBox.state = .on
        } else {
            bodyLabelCkBox.state = .off
        }
    }
    
    func setH1Titles(_ on: Bool) {
        if on {
            h1TitlesCkBox.state = .on
        } else {
            h1TitlesCkBox.state = .off
        }
    }
    
    func setStreamlined(_ on: Bool) {
        if on {
            streamlinedCkBox.state = .on
        } else {
            streamlinedCkBox.state = .off
        }
    }
    
    func setMathJax(_ on: Bool) {
        if on {
            mathJaxCkBox.state = .on
        } else {
            mathJaxCkBox.state = .off
        }
    }
    
    @objc func checkBoxClicked() {
        // No need to take any immediate action here
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        guard collection != nil else { return }
        collection!.title = collectionTitle.stringValue
        if collectionShortcut.stringValue != collection!.shortcut {
            collection!.shortcut = StringUtils.toCommon(collectionShortcut.stringValue)
            NotenikFolderList.shared.updateWithShortcut(linkStr: collection!.fullPath, shortcut: collection!.shortcut)
        }
        collection!.preferredExt = fileExtComboBox.stringValue
        collection!.otherFields = otherFieldsCkBox.state == NSControl.StateValue.on
        collection!.mirrorAutoIndex = (mirrorAutoIndexCkBox.state == .on)
        collection!.bodyLabel = (bodyLabelCkBox.state == .on)
        collection!.h1Titles = (h1TitlesCkBox.state == .on)
        collection!.streamlined = (streamlinedCkBox.state == .on)
        collection!.mathJax = (mathJaxCkBox.state == .on)
        defsRemoved.clear()
        let dict = collection!.dict
        dict.unlock()
        for checkBox in fieldSelectors {
            let def = dict.getDef(checkBox.title)
            if def == nil && checkBox.state == NSControl.StateValue.off {
                // No definition found or requested
            } else if def == nil && checkBox.state == NSControl.StateValue.on {
                // Add a new definition
                let added = dict.addDef(typeCatalog: collection!.typeCatalog,
                                        label: checkBox.title)
                if added == nil {
                    communicateError("Trouble adding definition to dictionary", alert: true)
                } else if checkBox.title == NotenikConstants.backlinks {
                    _ = dict.addDef(typeCatalog: collection!.typeCatalog, label: NotenikConstants.wikilinks)
                }
            } else if def != nil && checkBox.state == NSControl.StateValue.on {
                // Definition already in dictionary and requested
            } else if def != nil && checkBox.state == NSControl.StateValue.off {
                // Removing definition
                defsRemoved.append(def!)
                _ = dict.removeDef(def!)
                if checkBox.title == NotenikConstants.backlinks {
                    let def2 = dict.getDef(NotenikConstants.wikilinks)
                    if def2 != nil {
                        defsRemoved.append(def2!)
                        _ = dict.removeDef(def2!)
                    }
                }
            }
        }
        if !collection!.otherFields {
            dict.lock()
        }
        if defsRemoved.count > 0 {
            print("CollectionPrefsViewController: \(defsRemoved.count) field definitions removed")
        }
        application.stopModal(withCode: .OK)
        windowController!.close()
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {

        application.stopModal(withCode: .cancel)
        windowController!.close()
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "CollectionPrefsViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
}

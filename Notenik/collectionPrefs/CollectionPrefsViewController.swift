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
    
    @IBOutlet var collectionTitle:      NSTextField!
    @IBOutlet var fileExtComboBox:      NSComboBox!
    @IBOutlet var collectionShortcut:   NSTextField!
    @IBOutlet var mirrorAutoIndexCkBox: NSButton!
    @IBOutlet var bodyLabelCkBox:       NSButton!
    @IBOutlet var h1TitlesCkBox:        NSButton!
    @IBOutlet var pathControl:          NSPathControl!
    @IBOutlet var parentView:           NSView!
    
    var extPicker: FileExtensionPicker!
    
    var subView:                        NSView?
    
    var stackView:       NSStackView!
    
    var fieldsLabel:     NSTextField!
    
    var fieldSelectors:  [NSButton] = []
    
    var titleCkBox:      NSButton!
    var timestampCkBox:  NSButton!
    var tagsCkBox:       NSButton!
    var linkCkBox:       NSButton!
    var statusCkBox:     NSButton!
    var typeCkBox:       NSButton!
    var seqCkBox:        NSButton!
    var dateCkBox:       NSButton!
    var recursCkBox:     NSButton!
    var authorCkBox:     NSButton!
    var ratingCkBox:     NSButton!
    var indexCkBox:      NSButton!
    var codeCkBox:       NSButton!
    var teaserCkBox:     NSButton!
    var bodyCkBox:       NSButton!
    var dateAddedCkBox:  NSButton!
    var dateModifiedCkBox: NSButton!
    
    var checkBoxInsertionPoint = 0
    
    var otherFieldsCkBox: NSButton!
    
    /// Pass needed info from the Collection Juggler
    func passCollectionPrefsRequesterInfo(
                         collection: NoteCollection,
                         window: CollectionPrefsWindowController) {
        
        self.collection = collection
        self.windowController = window
        setCollectionValues()

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extPicker = FileExtensionPicker(fileExtComboBox: fileExtComboBox)
        makeViews()
    }
    
    /// Create the fields we need and stack them up vertically
    func makeViews() {
        
        collectionTitle.maximumNumberOfLines = 3
        makeStackView()
    }
    
    func makeStackView() {
        
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        
        titleCkBox = NSButton(checkboxWithTitle: NotenikConstants.title, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(titleCkBox)
        stackView.addArrangedSubview(titleCkBox)
        
        timestampCkBox = NSButton(checkboxWithTitle: NotenikConstants.timestamp, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(timestampCkBox)
        stackView.addArrangedSubview(timestampCkBox)
        
        tagsCkBox = NSButton(checkboxWithTitle: NotenikConstants.tags, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(tagsCkBox)
        stackView.addArrangedSubview(tagsCkBox)
        
        linkCkBox = NSButton(checkboxWithTitle: NotenikConstants.link, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(linkCkBox)
        stackView.addArrangedSubview(linkCkBox)
        
        statusCkBox = NSButton(checkboxWithTitle: NotenikConstants.status, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(statusCkBox)
        stackView.addArrangedSubview(statusCkBox)
        
        typeCkBox = NSButton(checkboxWithTitle: NotenikConstants.type, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(typeCkBox)
        stackView.addArrangedSubview(typeCkBox)
        
        seqCkBox = NSButton(checkboxWithTitle: NotenikConstants.seq, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(seqCkBox)
        stackView.addArrangedSubview(seqCkBox)
        
        dateCkBox = NSButton(checkboxWithTitle: NotenikConstants.date, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(dateCkBox)
        stackView.addArrangedSubview(dateCkBox)
        
        recursCkBox = NSButton(checkboxWithTitle: NotenikConstants.recurs, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(recursCkBox)
        stackView.addArrangedSubview(recursCkBox)
        
        authorCkBox = NSButton(checkboxWithTitle: NotenikConstants.author, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(authorCkBox)
        stackView.addArrangedSubview(authorCkBox)
        
        ratingCkBox = NSButton(checkboxWithTitle: NotenikConstants.rating, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(ratingCkBox)
        stackView.addArrangedSubview(ratingCkBox)
        
        indexCkBox = NSButton(checkboxWithTitle: NotenikConstants.index, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(indexCkBox)
        stackView.addArrangedSubview(indexCkBox)
        
        codeCkBox = NSButton(checkboxWithTitle: NotenikConstants.code, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(codeCkBox)
        stackView.addArrangedSubview(codeCkBox)
        
        teaserCkBox = NSButton(checkboxWithTitle: NotenikConstants.teaser, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(teaserCkBox)
        stackView.addArrangedSubview(teaserCkBox)
        
        bodyCkBox = NSButton(checkboxWithTitle: NotenikConstants.body, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(bodyCkBox)
        stackView.addArrangedSubview(bodyCkBox)
        
        dateAddedCkBox = NSButton(checkboxWithTitle: NotenikConstants.dateAdded, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(dateAddedCkBox)
        stackView.addArrangedSubview(dateAddedCkBox)
        
        dateModifiedCkBox = NSButton(checkboxWithTitle: NotenikConstants.dateModified, target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(dateModifiedCkBox)
        stackView.addArrangedSubview(dateModifiedCkBox)
        
        checkBoxInsertionPoint = stackView.arrangedSubviews.count - 1
        
        otherFieldsCkBox = NSButton(checkboxWithTitle: "Other fields allowed?", target: self, action: #selector(checkBoxClicked))
        stackView.addArrangedSubview(otherFieldsCkBox)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        if subView == nil {
            parentView.addSubview(stackView)
        } else {
            parentView.replaceSubview(subView!, with: stackView)
        }
        subView = stackView
        
        // Pin the grid to the edges of our main view
        stackView!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        stackView!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        stackView!.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        stackView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
        
        setCollectionValues()
        
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
        setFieldsForCollection()
        setOtherFieldsAllowed(collection!.otherFields)
        setMirrorAutoIndex(collection!.mirrorAutoIndex)
        setBodyLabel(collection!.bodyLabel)
        setH1Titles(collection!.h1Titles)
    }
    
    func setFieldsForCollection() {
        
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
                fieldSelectors.append(newCheckBox)
                stackView.insertArrangedSubview(newCheckBox, at: checkBoxInsertionPoint)
                checkBoxInsertionPoint += 1
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
    
    @objc func checkBoxClicked() {
        // No need to take any immediate action here
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        guard collection != nil else { return }
        collection!.title = collectionTitle.stringValue
        collection!.shortcut = collectionShortcut.stringValue
        collection!.preferredExt = fileExtComboBox.stringValue
        collection!.otherFields = otherFieldsCkBox.state == NSControl.StateValue.on
        collection!.mirrorAutoIndex = (mirrorAutoIndexCkBox.state == .on)
        collection!.bodyLabel = (bodyLabelCkBox.state == .on)
        collection!.h1Titles = (h1TitlesCkBox.state == .on)
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
                }
            } else if def != nil && checkBox.state == NSControl.StateValue.on {
                // Definition already in dictionary and requested
            } else if def != nil && checkBox.state == NSControl.StateValue.off {
                // Removing definition
                _ = dict.removeDef(def!)
            }
        }
        if !collection!.otherFields {
            dict.lock()
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

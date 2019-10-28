//
//  TemplateViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CollectionPrefsViewController: NSViewController {
    
    var owner: CollectionPrefsOwner?
    var collection: NoteCollection?
    var windowController: CollectionPrefsWindowController?
    
    @IBOutlet var stackView: NSStackView!
    
    var titleLabel:      NSTextField!
    var collectionTitle: NSTextField!
    
    let fileExtensions = ["txt", "md", "text", "markdown", "mdown", "mkdown", "mktext", "mdtext", "nnk", "notenik" ]
    var fileExtLabel:    NSTextField!
    var fileExtComboBox: NSComboBox!
    
    var fieldsLabel:     NSTextField!
    
    var fieldSelectors:  [NSButton] = []
    
    var titleCkBox:      NSButton!
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
    
    var checkBoxInsertionPoint = 0
    
    var otherFieldsCkBox: NSButton!
    
    var okButton:        NSButton!
    var cancelButton:    NSButton!
    var actionStack:     NSStackView!
    
    /// Pass needed info from the Collection Juggler
    func passCollectionPrefsRequesterInfo(owner: CollectionPrefsOwner,
                         collection: NoteCollection,
                         window: CollectionPrefsWindowController) {
        self.owner = owner
        self.collection = collection
        self.windowController = window
        if collectionTitle != nil {
            collectionTitle!.stringValue = collection.title
        }
        setFileExt(collection.preferredExt)
        setFieldsForCollection()
        setOtherFieldsAllowed(collection.otherFields)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeStackView()
    }
    
    /// Create the fields we need and stack them up vertically
    func makeStackView() {
        
        titleLabel = NSTextField(labelWithString: "Collection Title: ")
        stackView.addArrangedSubview(titleLabel)
        
        collectionTitle = NSTextField(string: "")
        collectionTitle.maximumNumberOfLines = 3
        stackView.addArrangedSubview(collectionTitle)
        
        fileExtLabel = NSTextField(labelWithString: "Preferred File Extension: ")
        stackView.addArrangedSubview(fileExtLabel)
        
        fileExtComboBox = NSComboBox()
        fileExtComboBox.addItems(withObjectValues: fileExtensions)
        stackView.addArrangedSubview(fileExtComboBox)
        
        fieldsLabel = NSTextField(labelWithString: "Fields: ")
        stackView.addArrangedSubview(fieldsLabel)
        
        titleCkBox = NSButton(checkboxWithTitle: "Title", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(titleCkBox)
        stackView.addArrangedSubview(titleCkBox)
        
        tagsCkBox = NSButton(checkboxWithTitle: "Tags", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(tagsCkBox)
        stackView.addArrangedSubview(tagsCkBox)
        
        linkCkBox = NSButton(checkboxWithTitle: "Link", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(linkCkBox)
        stackView.addArrangedSubview(linkCkBox)
        
        statusCkBox = NSButton(checkboxWithTitle: "Status", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(statusCkBox)
        stackView.addArrangedSubview(statusCkBox)
        
        typeCkBox = NSButton(checkboxWithTitle: "Type", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(typeCkBox)
        stackView.addArrangedSubview(typeCkBox)
        
        seqCkBox = NSButton(checkboxWithTitle: "Seq", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(seqCkBox)
        stackView.addArrangedSubview(seqCkBox)
        
        dateCkBox = NSButton(checkboxWithTitle: "Date", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(dateCkBox)
        stackView.addArrangedSubview(dateCkBox)
        
        recursCkBox = NSButton(checkboxWithTitle: "Recurs", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(recursCkBox)
        stackView.addArrangedSubview(recursCkBox)
        
        authorCkBox = NSButton(checkboxWithTitle: "Author", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(authorCkBox)
        stackView.addArrangedSubview(authorCkBox)
        
        ratingCkBox = NSButton(checkboxWithTitle: "Rating", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(ratingCkBox)
        stackView.addArrangedSubview(ratingCkBox)
        
        indexCkBox = NSButton(checkboxWithTitle: "Index", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(indexCkBox)
        stackView.addArrangedSubview(indexCkBox)
        
        codeCkBox = NSButton(checkboxWithTitle: "Code", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(codeCkBox)
        stackView.addArrangedSubview(codeCkBox)
        
        teaserCkBox = NSButton(checkboxWithTitle: "Teaser", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(teaserCkBox)
        stackView.addArrangedSubview(teaserCkBox)
        
        bodyCkBox = NSButton(checkboxWithTitle: "Body", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(bodyCkBox)
        stackView.addArrangedSubview(bodyCkBox)
        
        dateAddedCkBox = NSButton(checkboxWithTitle: "Date Added", target: self, action: #selector(checkBoxClicked))
        fieldSelectors.append(dateAddedCkBox)
        stackView.addArrangedSubview(dateAddedCkBox)
        
        checkBoxInsertionPoint = stackView.arrangedSubviews.count - 1
        
        otherFieldsCkBox = NSButton(checkboxWithTitle: "Other fields allowed?", target: self, action: #selector(checkBoxClicked))
        stackView.addArrangedSubview(otherFieldsCkBox)
        
        okButton = NSButton(title: "OK", target: self, action: #selector(okButtonClicked))
        cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelButtonClicked))
        actionStack = NSStackView(views: [okButton, cancelButton])
        
        stackView.addArrangedSubview(actionStack)
        
        guard collection != nil else { return }
        
        collectionTitle.stringValue = collection!.title
        setFileExt(collection!.preferredExt)
        setFieldsForCollection()
        setOtherFieldsAllowed(collection!.otherFields)
    }
    
    func setFileExt(_ ext: String?) {
        guard ext != nil && ext != "" else { return }
        var i = 0
        var found = false
        while i < fileExtensions.count && !found {
            if ext == fileExtensions[i] {
                found = true
                fileExtComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            fileExtComboBox.addItem(withObjectValue: ext!)
            fileExtComboBox.selectItem(at: i)
        }
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
            otherFieldsCkBox.state = NSControl.StateValue.on
        } else {
            otherFieldsCkBox.state = NSControl.StateValue.off
        }
    }
    
    @objc func checkBoxClicked() {
        // No need to take any immediate action here
    }
    
    @objc func okButtonClicked() {
        guard collection != nil else { return }
        collection!.title = collectionTitle.stringValue
        collection!.preferredExt = fileExtComboBox.stringValue
        collection!.otherFields = otherFieldsCkBox.state == NSControl.StateValue.on
        let dict = collection!.dict
        for checkBox in fieldSelectors {
            let def = dict.getDef(checkBox.title)
            if def == nil && checkBox.state == NSControl.StateValue.off {
                // No definition found or requested
            } else if def == nil && checkBox.state == NSControl.StateValue.on {
                // Add a new definition
                _ = dict.addDef(typeCatalog: collection!.typeCatalog, label: checkBox.title)
            } else if def != nil && checkBox.state == NSControl.StateValue.on {
                // Definition already in dictionary and requested
            } else if def != nil && checkBox.state == NSControl.StateValue.off {
                // Removing definition
                _ = dict.removeDef(def!)
            }
        }
        owner!.collectionPrefsModified(ok: true, collection: collection!, window: windowController!)
    }
    
    @objc func cancelButtonClicked() {
        owner!.collectionPrefsModified(ok: false, collection: collection!, window: windowController!)
    }
    
}

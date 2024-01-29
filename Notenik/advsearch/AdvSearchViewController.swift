//
//  AdvSearchViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 10/19/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class AdvSearchViewController: NSViewController {
    
    var collectionController: CollectionWindowController?
    var window: AdvSearchWindowController?
    
    var noteIO: NotenikIO? {
        get {
            return _noteIO
        }
        set {
            _noteIO = newValue
            tailorForCollection()
        }
    }
    var _noteIO: NotenikIO?
    
    @IBOutlet var searchText: NSTextField!
    
    @IBOutlet var titleField: NSButton!
    @IBOutlet var akaField: NSButton!
    @IBOutlet var linkField: NSButton!
    @IBOutlet var tagsField: NSButton!
    @IBOutlet var authorField: NSButton!
    @IBOutlet var bodyField: NSButton!
    
    @IBOutlet var caseSensitive: NSButton!
    
    @IBOutlet var searchAll: NSButton!
    @IBOutlet var searchWithin: NSButton!
    @IBOutlet var searchForward: NSButton!
    
    var searchOptions: SearchOptions {
        get {
            return _searchOptions
        }
        set {
            _searchOptions = newValue
            tailorForOptions()
        }
    }
    var _searchOptions = SearchOptions()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tailorForOptions()
        tailorForCollection()
    }
    
    func tailorForCollection() {
        guard isViewLoaded else { return }
        guard let io = noteIO else { return }
        guard let collection = io.collection else { return }
        if collection.akaFieldDef == nil {
            akaField.state = .off
            akaField.isEnabled = false
        } else {
            akaField.state = .on
            akaField.isEnabled = true
        }
    }
    
    func tailorForOptions() {
        guard isViewLoaded else { return }
        searchText.stringValue = _searchOptions.searchText
        setCkBox(ckBox: titleField, selected: _searchOptions.titleField)
        setCkBox(ckBox: akaField, selected: _searchOptions.akaField)
        setCkBox(ckBox: linkField, selected: _searchOptions.linkField)
        setCkBox(ckBox: tagsField, selected: _searchOptions.tagsField)
        setCkBox(ckBox: authorField, selected: _searchOptions.authorField)
        setCkBox(ckBox: titleField, selected: _searchOptions.titleField)
        setCkBox(ckBox: bodyField, selected: _searchOptions.bodyField)
        setCkBox(ckBox: caseSensitive, selected: _searchOptions.caseSensitive)
        searchAll.state = .on
    }
    
    func setCkBox(ckBox: NSButton, selected: Bool) {
        if selected {
            ckBox.state = .on
        } else {
            ckBox.state = .off
        }
    }
    
    @IBAction func searchScope(_ sender: Any) {
        
    }
    
    @IBAction func cancelSearch(_ sender: Any) {
        closeWindow()
    }
    
    @IBAction func okToSearch(_ sender: Any) {
        searchOptions.searchText = searchText.stringValue
        searchOptions.akaField = akaField.state == .on
        searchOptions.authorField = authorField.state == .on
        searchOptions.bodyField = bodyField.state == .on
        searchOptions.linkField = linkField.state == .on
        searchOptions.tagsField = tagsField.state == .on
        searchOptions.titleField = titleField.state == .on
        searchOptions.caseSensitive = caseSensitive.state == .on
        
        if searchAll.state == .on {
            searchOptions.scope = .all
        } else if searchWithin.state == .on {
            searchOptions.scope = .within
        } else if searchForward.state == .on {
            searchOptions.scope = .forward
        }
        
        guard let collectionWC = collectionController else { return }
        collectionWC.advSearchNow(options: searchOptions)
        closeWindow()
    }
    
    /// Close the Advanced Search Window.
    func closeWindow() {
        guard window != nil else { return }
        window!.close()
    }
    
}

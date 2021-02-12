//
//  NewNameViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/7/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

/// Second tab; get the desired name of the new Collection.
class NewNameViewController: NSViewController {
    
    var tabsVC: NewCollectionViewController?

    @IBOutlet var nameTextField: NSTextField!
    
    @IBOutlet var parentFolderPath: NSTextField!
    
    var parentURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if parentURL != nil {
            parentFolderPath.stringValue = parentURL!.path
        }
    }
    
    var collectionName: String {
        return StringUtils.trim(nameTextField.stringValue)
    }
    
    func setParent(_ parent: URL) {
        parentURL = parent
        if isViewLoaded {
            parentFolderPath.stringValue = parentURL!.path
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.selectTab(index: 0)
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.selectTab(index: 2)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
}

//
//  NewLocationViewController.swift
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

/// Uses radio buttons to indicate whether the new Collection should be within
/// Notenik's special iCloud container, or whether it should be created
/// somewhere "in the wild".
class NewLocationViewController: NSViewController {
    
    var tabsVC: NewCollectionViewController?
    
    @IBOutlet var iCloudParent: NSButton!
    @IBOutlet var userSelectedParent: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var parentInICloud: Bool {
        return iCloudParent.state == .on
    }
    
    /// Doesn't need to do anything, but both radio buttons
    /// need to point here for their actions so that they
    /// will act like radio buttons.
    @IBAction func locationButtonSelected(_ sender: Any) {

    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.selectTab(index: 1)
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
    
    
}

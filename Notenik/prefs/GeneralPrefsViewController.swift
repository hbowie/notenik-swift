//
//  GeneralPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/29/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class GeneralPrefsViewController: NSViewController {
    
    let appPrefs = AppPrefs.shared

    @IBOutlet var confirmDeletesYes: NSButton!
    
    @IBOutlet var confirmDeletesNo: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if appPrefs.confirmDeletes {
            confirmDeletesYes.state = .on
        } else {
            confirmDeletesNo.state = .on
        }
    }
    
    @IBAction func appPrefsConfirmDeletes (_ sender: Any) {
        if confirmDeletesYes.state == .on {
            appPrefs.confirmDeletes = true
        } else if confirmDeletesNo.state == .on {
            appPrefs.confirmDeletes = false
        }
    }
    
    @IBAction func appPrefsOK(_ sender: Any) {
        self.view.window!.close()
    }
    
}

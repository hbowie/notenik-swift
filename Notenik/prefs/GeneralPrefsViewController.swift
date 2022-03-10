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

import NotenikLib

class GeneralPrefsViewController: NSViewController, PrefsTabVC {
    
    let appPrefs = AppPrefs.shared

    @IBOutlet var confirmDeletesYes: NSButton!
    
    @IBOutlet var confirmDeletesNo: NSButton!
    
    @IBOutlet var openTipsAtStartup: NSButton!
    
    @IBOutlet var appAppearance: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if appPrefs.confirmDeletes {
            confirmDeletesYes.state = .on
        } else {
            confirmDeletesNo.state = .on
        }
        if appPrefs.tipsAtStartup {
            openTipsAtStartup.state = .on
        } else {
            openTipsAtStartup.state = .off
        }
        let appearance = appPrefs.appAppearance
        switch appearance {
        case "system": appAppearance.selectItem(at: 0)
        case "light":  appAppearance.selectItem(at: 1)
        case "dark":   appAppearance.selectItem(at: 2)
        default: break
        }
    }
    
    @IBAction func appPrefsConfirmDeletes (_ sender: Any) {
        if confirmDeletesYes.state == .on {
            appPrefs.confirmDeletes = true
        } else if confirmDeletesNo.state == .on {
            appPrefs.confirmDeletes = false
        }
    }
    
    @IBAction func checkBoxStartupTips(_ sender: Any) {
        if openTipsAtStartup.state == .on {
            appPrefs.tipsAtStartup = true
        } else {
            appPrefs.tipsAtStartup = false
        }
    }
    
    @available(macOS 10.14, *)
    @IBAction func appAppearanceSelected(_ sender: Any) {
        let ix = appAppearance.indexOfSelectedItem
        switch ix {
        case 0:
            appPrefs.appAppearance = "system"
            NSApp.appearance = NSAppearance()
        case 1:
            appPrefs.appAppearance = "light"
            NSApp.appearance = NSAppearance(named: .aqua)
        case 2:
            appPrefs.appAppearance = "dark"
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            break
        }
    }
    
    @IBAction func appPrefsOK(_ sender: Any) {
        self.view.window!.close()
    }
    
    /// Called when the user is leaving this tab for another one.
    func leavingTab() {

    }
    
}

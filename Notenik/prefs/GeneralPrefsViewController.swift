//
//  GeneralPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/29/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class GeneralPrefsViewController: NSViewController, PrefsTabVC {
    
    let appPrefs = AppPrefs.shared
    
    let spacingOptions: [String] = [
        "no spaces",
        "1 space",
        "2 spaces",
        "3 spaces",
        "4 spaces",
        "5 spaces",
        "6 spaces",
        "7 spaces",
        "8 spaces",
        "9 spaces"
    ]

    @IBOutlet var confirmDeletesYes: NSButton!
    
    @IBOutlet var confirmDeletesNo: NSButton!
    
    @IBOutlet var openTipsAtStartup: NSButton!
    
    @IBOutlet var appAppearance: NSPopUpButton!
    
    @IBOutlet var indentSpacesPopUpButton: NSPopUpButton!
    
    @IBOutlet var grantAccessOptPopUpButton: NSPopUpButton!
    
    @IBOutlet var mastodonHandleTextField: NSTextField!
    
    @IBOutlet var mastodonDomainTextField: NSTextField!
    
    @IBOutlet var idFolderLevelsField: NSTextField!
    
    @IBOutlet var idFolderSepField: NSTextField!
    
    @IBOutlet var horizListScrollBarField: NSPopUpButton!
    
    @IBOutlet var inlineLongTextField: NSPopUpButton!
    
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
        
        switch appPrefs.horizontalListScrollBar {
            case "on": horizListScrollBarField.selectItem(at: 0)
            case "off":  horizListScrollBarField.selectItem(at: 1)
            default: break;
        }
        
        switch appPrefs.auxLongText {
        case false:
            inlineLongTextField.selectItem(at: 0)
        case true:
            inlineLongTextField.selectItem(at: 1)
        }
        
        indentSpacesPopUpButton.removeAllItems()
        indentSpacesPopUpButton.addItems(withTitles: spacingOptions)
        indentSpacesPopUpButton.selectItem(at: appPrefs.indentSpacing)
        
        let grantAccessOpt = appPrefs.grantAccessOption
        grantAccessOptPopUpButton.selectItem(at: grantAccessOpt - 1)
        
        mastodonHandleTextField.stringValue = appPrefs.mastodonHandle
        mastodonDomainTextField.stringValue = appPrefs.mastodonDomain
        
        idFolderLevelsField.stringValue = "\(appPrefs.idFolderLevels)"
        idFolderSepField.stringValue = appPrefs.idFolderSep
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
    
    @IBAction func horizListScrollBarUpdated(_ sender: Any) {
        switch horizListScrollBarField.indexOfSelectedItem {
        case 0:
            appPrefs.horizontalListScrollBar = "on"
        case 1:
            appPrefs.horizontalListScrollBar = "off"
        default:
            break
        }
        CollectionJuggler.shared.adjustListViews()
    }
    
    @IBAction func inlineLongTextPopupUpdated(_ sender: NSPopUpButton) {
        switch inlineLongTextField.indexOfSelectedItem {
        case 0:
            appPrefs.auxLongText = false
        case 1:
            appPrefs.auxLongText = true
        default:
            appPrefs.auxLongText = false
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
        DisplayPrefs.shared.displayRefresh()
    }
    
    @IBAction func indentSpacingSelected(_ sender: Any) {
        appPrefs.indentSpacing = indentSpacesPopUpButton.indexOfSelectedItem
        CollectionJuggler.shared.adjustListViews()
    }
    
    @IBAction func appPrefsOK(_ sender: Any) {
        appPrefs.mastodonHandle = mastodonHandleTextField.stringValue
        appPrefs.mastodonDomain = mastodonDomainTextField.stringValue
        if let folderLevels = Int(idFolderLevelsField.stringValue) {
            if folderLevels > 0 && folderLevels < 9 {
                appPrefs.idFolderLevels = folderLevels
            }
        }
        appPrefs.idFolderSep = idFolderSepField.stringValue
        self.view.window!.close()
    }
    
    @IBAction func mastodonHandleEdited(_ sender: Any) {
        appPrefs.mastodonHandle = mastodonHandleTextField.stringValue
    }
    
    @IBAction func mastodonDomainEdited(_ sender: Any) {
        appPrefs.mastodonDomain = mastodonDomainTextField.stringValue
    }
    
    @IBAction func funcgrantAccessOptionSelected(_ sender: Any) {
        let selIndex = grantAccessOptPopUpButton.indexOfSelectedItem
        appPrefs.grantAccessOption = selIndex + 1
    }
    
    @IBAction func idFolderLevelsEdited(_ sender: Any) {
        if let folderLevels = Int(idFolderLevelsField.stringValue) {
            if folderLevels > 0 && folderLevels < 9 {
                appPrefs.idFolderLevels = folderLevels
            }
        }
    }
    
    @IBAction func idFolderSepEdited(_ sender: Any) {
        appPrefs.idFolderSep = idFolderSepField.stringValue
    }
    
    /// Called when the user is leaving this tab for another one.
    func leavingTab() {

    }
    
}

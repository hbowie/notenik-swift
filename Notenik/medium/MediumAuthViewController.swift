//
//  MediumAuthViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/29/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class MediumAuthViewController: NSViewController {
    
    var wc: MediumPubWindowController!
    
    var info =    MediumInfo()

    @IBOutlet var tokenField: NSTextField!
    @IBOutlet var userNameField: NSTextField!
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var msgField: NSTextField!
    @IBOutlet var authenticateButton: NSButton!
    
    var loadOK = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if info.authToken.count > 0 {
            tokenField.stringValue = info.authToken
        }
        loadOK = true
        mediumUpdate()
    }
    
    override func viewWillDisappear() {
        checkForUserUpdate()
    }
    
    /// Token field updated.
    @IBAction func tokenAction(_ sender: Any) {
        checkForUserUpdate()
    }
    
    @IBAction func authenticateAction(_ sender: Any) {
        wc.authenticate()
    }
    
    /// See if the user updated the token field.
    func checkForUserUpdate() {
        if tokenField.stringValue != info.authToken {
            info.authToken = tokenField.stringValue
            AppPrefs.shared.mediumToken = tokenField.stringValue
            if info.authToken.isEmpty {
                info.status = .tokenNeeded
            } else {
                info.status = .authenticationNeeded
            }
            wc.authenticate()
        }
    }
    
    /// Update UI based on latest info from the Medium Info block. 
    func mediumUpdate() {
        guard loadOK else { return }
        tokenField.stringValue = info.authToken
        userNameField.stringValue = info.username
        nameField.stringValue = info.name
        switch info.status {
        case .authenticationStarted:
            authenticateButton.state = .off
            msgField.stringValue = info.msg
        case .tokenNeeded, .authenticationFailed, .internalError:
            authenticateButton.state = .on
            msgField.stringValue = info.msg
        default:
            authenticateButton.state = .on
            msgField.stringValue = "Authentication Succeeded"
        }
    }
}

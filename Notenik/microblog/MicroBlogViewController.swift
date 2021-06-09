//
//  MicroBlogViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/26/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class MicroBlogViewController: NSViewController, MicroBlogUI {
    
    let appPrefs = AppPrefs.shared
    
    var wc:       MicroBlogWindowController?
    var info =    MicroBlogInfo()
    var microBlogInt: MicroBlogIntegrator?

    @IBOutlet var msgField: NSTextField!
    @IBOutlet var noteTitleField: NSTextField!
    @IBOutlet var userNameField: NSTextField!
    @IBOutlet var appTokenField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        microBlogInt = MicroBlogIntegrator(ui: self, info: info)
        userNameField.stringValue = appPrefs.microBlogUser
        appTokenField.stringValue = appPrefs.microBlogToken
        msgField.stringValue = ""
        _ = checkNameAndToken()
        noteTitleField.stringValue = ""
        refreshNote()
    }
    
    func refreshNote() {
        if info.note != nil {
            noteTitleField.stringValue = info.note!.title.value
        }
    }
    
    @IBAction func userNameEntered(_ sender: Any) {
        appPrefs.microBlogUser = userNameField.stringValue
        _ = checkNameAndToken()
    }
    
    @IBAction func appTokenEntered(_ sender: Any) {
        appPrefs.microBlogToken = appTokenField.stringValue
        _ = checkNameAndToken()
    }
    
    func checkNameAndToken() -> Bool {
        if appPrefs.microBlogUser.count == 0 {
            if appPrefs.microBlogToken.count == 0 {
                msgField.stringValue = "Enter Username and App Token"
                return false
            } else {
                msgField.stringValue = "Enter Username"
                return false
            }
        } else if appPrefs.microBlogToken.count == 0 {
            msgField.stringValue = "Enter App Token"
            return false
        }
        return true
    }
    
    @IBAction func publish(_ sender: Any) {
        // guard let note = info.note else { return }
        // guard checkNameAndToken() else { return }
    }
    
    @IBAction func done(_ sender: Any) {
        if userNameField.stringValue != appPrefs.microBlogUser {
            userNameEntered(self)
        }
        if appTokenField.stringValue != appPrefs.microBlogToken {
            appTokenEntered(self)
        }
        guard wc != nil else { return }
        wc!.close()
    }
    
    func microBlogUpdate() {
        
    }
}

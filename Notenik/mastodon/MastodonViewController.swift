//
//  MastodonViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/22.
//  Copyright © 2022 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import MastodonKit

import NotenikLib

class MastodonViewController: NSViewController {
    
    let appPrefs = AppPrefs.shared
    let info = MastodonInfo.shared
    
    var wc: MastodonWindowController!
    var window: NSWindow!
    
    @IBOutlet var userNameTextField: NSTextField!
    @IBOutlet var domainTextField:   NSTextField!
    
    @IBOutlet var statusTextField:      NSTextField!
    
    @IBOutlet var postButton: NSButton!
    
    var mastodon: Client?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.stringValue = appPrefs.mastodonUserName
        domainTextField.stringValue = appPrefs.mastodonDomain
        authenticate()
    }

    @IBAction func userNameEdited(_ sender: Any) {
        authenticate()
    }
    
    @IBAction func domainTextFieldEdited(_ sender: Any) {
        authenticate()
    }
    
    @IBAction func postNote(_ sender: Any) {
    }
    
    @IBAction func dismissWindow(_ sender: Any) {
        window.close()
    }
    
    func authenticate() {
        
        postButton.isEnabled = false
        
        statusTextField.stringValue = ""
        
        guard !userNameTextField.stringValue.isEmpty else {
            statusTextField.stringValue = "You must supply your Mastodon user name"
            return
        }
        
        guard !domainTextField.stringValue.isEmpty else {
            statusTextField.stringValue = "You must supply your Mastodon domain name"
            return
        }
        
        info.username = statusTextField.stringValue
        info.domain = domainTextField.stringValue
        
        info.client = Client(baseURL: "https://\(info.domain)")
        
        let request = Clients.register(clientName: info.clientName,
                                       scopes: [.read, .write, .follow],
                                       website: info.appWebsite)
        
        guard let client = info.client else {
            statusTextField.stringValue = "Error creating a Mastodon client"
            return
        }
        
        client.run(request) { result in
            if let application = result.value {
                print("id: \(application.id)")
                print("redirect uri: \(application.redirectURI)")
                print("client id: \(application.clientID)")
                print("client secret: \(application.clientSecret)")
            }
        }
        
        statusTextField.stringValue = "Mastodon Client Initiated"
        
        /*
        
        if serverURLTextField.stringValue != appPrefs.mastodonURL {
            appPrefs.mastodonURL = serverURLTextField.stringValue
        }
        
        if accessTokenTextField.stringValue != appPrefs.mastodonToken {
            appPrefs.mastodonToken = accessTokenTextField.stringValue
        }
         */
    }
    
}

//
//  PublishWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/28/20.
//
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class MediumPubWindowController: NSWindowController, MediumUI {
    
    let appPrefs = AppPrefs.shared
    var mediumInt: MediumIntegrator!
    
    var info =    MediumInfo()
    
    var win:      NSWindow!
    var tabVC:    MediumTabViewController!
    var tabItem1: NSTabViewItem!
    var tabItem2: NSTabViewItem!
    var tabVC1:   MediumAuthViewController!
    var tabVC2:   MediumPubViewController!
    
    var loadOK = false
    
    override func windowWillLoad() {
        super.windowWillLoad()
        mediumInt = MediumIntegrator(ui: self, info: info)
        let token = appPrefs.mediumToken
        info.authToken = token
        authenticate()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard window != nil else { return }
        win = window!
        guard contentViewController != nil else { return }
        guard contentViewController! is MediumTabViewController else { return }
        tabVC = contentViewController! as? MediumTabViewController
        guard tabVC.tabViewItems.count >= 2 else { return }
        tabItem1 = tabVC.tabViewItems[0]
        tabItem2 = tabVC.tabViewItems[1]
        guard tabItem1.viewController != nil else { return }
        guard tabItem1.viewController! is MediumAuthViewController else { return }
        tabVC1 = tabItem1.viewController! as? MediumAuthViewController
        guard tabItem2.viewController != nil else { return }
        guard tabItem2.viewController! is MediumPubViewController else { return }
        tabVC2 = tabItem2.viewController! as? MediumPubViewController
        tabVC1.wc = self
        tabVC1.info = info
        tabVC2.wc = self
        tabVC2.info = info
        loadOK = true
        mediumUpdate()
    }
    
    var note: Note? {
        get {
            return info.note
        }
        set {
            info.note = newValue
        }
    }
    
    func authenticate() {
        mediumInt.getUserDetails()
    }
    
    func publish() {
        mediumInt.submitPost()
    }
    
    /// Allow the user to view the submitted draft.  
    func view() {
        guard info.postURL.count > 0 else { return }
        guard info.status == .postSucceeded else { return }
        guard let url = URL(string: info.postURL) else { return }
        _ = NSWorkspace.shared.open(url)
    }
    
    /// Update the UI based on changes in Medium Info. This method is part of the
    /// MediumUI protocol that is passed to the Medium Integrator. 
    func mediumUpdate() {
        guard loadOK else { return }
        tabVC1.mediumUpdate()
        tabVC2.mediumUpdate()
    }
    
}

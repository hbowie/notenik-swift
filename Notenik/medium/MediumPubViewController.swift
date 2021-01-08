//
//  MediumPubViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/29/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class MediumPubViewController: NSViewController {
    
    var wc: MediumPubWindowController!
    
    var info =    MediumInfo()

    @IBOutlet var titleField: NSTextField!
    @IBOutlet var urlField: NSTextField!
    @IBOutlet var msgField: NSTextField!
    
    @IBOutlet var viewDraftButton: NSButton!
    @IBOutlet var publishDraftButton: NSButton!
    
    var loadOK = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadOK = true
        mediumUpdate()
    }
    
    @IBAction func publishAction(_ sender: Any) {
        wc.publish()
    }
    
    @IBAction func viewAction(_ sender: Any) {
        wc.view()
    }
    
    /// Update UI based on latest info from the Medium Info block. 
    func mediumUpdate() {
        guard loadOK else { return }
        if info.note != nil {
            titleField.stringValue = info.note!.title.value
        }
        urlField.stringValue = info.postURL
        msgField.stringValue = info.msg
        switch info.status {
        case .postStarted:
            publishDraftButton.state = .off
            viewDraftButton.state = .off
        case .postSucceeded:
            publishDraftButton.state = .off
            viewDraftButton.state = .on
        default:
            publishDraftButton.state = .on
            viewDraftButton.state = .off
        }
    }
}

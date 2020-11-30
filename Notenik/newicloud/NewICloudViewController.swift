//
//  NewICloudViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikUtils

class NewICloudViewController: NSViewController {
    
    var window: NewICloudWindowController!
    
    var juggler: CollectionJuggler!
    
    @IBOutlet var textField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        juggler = CollectionJuggler.shared
    }
    
    @IBAction func cancel(_ sender: Any) {
        window.close()
    }
    
    @IBAction func okay(_ sender: Any) {
        _ = juggler.newCollectionInICloud(folderName: textField.stringValue)
        window.close()
    }
}

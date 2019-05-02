//
//  ParentLocationViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/30/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ParentLocationViewController: NSViewController {
    
    var window:      ParentLocationWindowController?
    var juggler:     CollectionJuggler?
    var requestType: CollectionRequestType?

    @IBOutlet var freeRangeButton:   NSButton!
    @IBOutlet var sandBoxButton:     NSButton!
    @IBOutlet var sandBoxFolderName: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func locationSelection(_ sender: Any) {
        
    }
    
    @IBAction func userClickedOK(_ sender: Any) {
        window!.close()
        print("User Clicked OK!")
        var parentOption: ParentOptions = .sandbox
        if freeRangeButton.state == .on {
            parentOption = .freerange
        }
        juggler!.parentLocationOK(requestType: requestType!, parentOption: parentOption, folderName: sandBoxFolderName.stringValue)
    }
    
    @IBAction func userClickedCancel(_ sender: Any) {
        window!.close()
        print("User Clicked Cancel!")
        juggler!.parentLocationCancel()
    }
}

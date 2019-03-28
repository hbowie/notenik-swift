//
//  LogViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 3/28/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class LogViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setText(logText: String) {
        textView.string = logText
    }
    
}

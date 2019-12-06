//
//  MarkdownPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 12/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class MarkdownPrefsViewController: NSViewController {

    @IBOutlet var downButton: NSButton!
    @IBOutlet var inkButton:  NSButton!
    
    let prefs = AppPrefs.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let parser = prefs.markdownParser
        switch parser {
        case "down":
            downButton.state = .on
        case "ink":
            inkButton.state = .on
        default:
            downButton.state = .on
        }
    }
    
    // Save the user's preferences.
    @IBAction func buttonAction(_ sender: NSButton) {
        if downButton.state == .on {
            prefs.markdownParser = "down"
        } else if inkButton.state == .on {
            prefs.markdownParser = "ink"
        }
    }
}

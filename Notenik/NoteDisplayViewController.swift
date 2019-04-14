//
//  NoteDisplayViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import WebKit

class NoteDisplayViewController: NSViewController, WKUIDelegate {
    
    @IBOutlet var webView: WKWebView!
    
    let noteDisplay = NoteDisplay()
    
    var html = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
    }
    
    func display(note: Note) {
        html = noteDisplay.display(note)
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            Logger.shared.log(skip: false, indent: 0, level: LogLevel.moderate,
                              message: "load html String returned nil")
        }
    }
    
    /// Reload the Note's HTML when user requests this from Toolbar button.
    /// This can be helpful after the user has clicked on a link in the Note's display,
    /// to get back to the original display of the Note.
    func reload() {
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            Logger.shared.log(skip: false, indent: 0, level: LogLevel.moderate,
                              message: "load html String returned nil")
        }
    }
    
}

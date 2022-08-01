//
//  QueryOutputViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/25/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import WebKit

import NotenikLib

class QueryOutputViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = self.view.window else {
            return
        }
        var windowPosition = ""
        let frame = window.frame
        windowPosition.append("\(frame.minX);")
        windowPosition.append("\(frame.minY);")
        windowPosition.append("\(frame.width);")
        windowPosition.append("\(frame.height);")
        AppPrefs.shared.queryOutputWindowNumbers = windowPosition
    }
    
    func loadHTMLString(_ string: String) {
        webView.loadHTMLString(string, baseURL: nil)
    }
    
}

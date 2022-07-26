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

class QueryOutputViewController: NSViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadHTMLString(_ string: String) {
        webView.loadHTMLString(string, baseURL: nil)
    }
    
}

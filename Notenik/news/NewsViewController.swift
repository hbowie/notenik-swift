//
//  NewsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/9/21.
//  Copyright © 2021 PowerSurge Publishing. All rights reserved.
//

import Cocoa
import WebKit

class NewsViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    @IBOutlet var webView: WKWebView!
    
    var webConfig: WKWebViewConfiguration!
    
    /* override func loadView() {
        print("NewsViewController.loadView")
        // webConfig = WKWebViewConfiguration()
        // webView = WKWebView(frame: .zero, configuration: webConfig)
        
        // view = webView
    } */

    override func viewDidLoad() {
        super.viewDidLoad()
        print("NewsViewController.viewDidLoad")
        webView.uiDelegate = self
        webView.navigationDelegate = self
        let html = "<html><p>Notenik News</p></html>"
        webView.loadHTMLString(html, baseURL: nil)
    }
    
}

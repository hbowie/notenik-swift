//
//  NewsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/9/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
@preconcurrency import WebKit

import NotenikLib
import NotenikUtils

class NewsViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    let fm = FileManager.default
    let format: MarkedupFormat = .htmlDoc
    let docTitle = "The Latest News about Notenik"
    let displayPrefs = DisplayPrefs.shared
    
    @IBOutlet var webView: WKWebView!
    
    var webConfig: WKWebViewConfiguration!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        loadHTML()
    }
    
    /// Load the HTML to be displayed in the web view.
    func loadHTML() {
        let code = Markedup(format: format)
        var css = displayPrefs.displayCSS!
        if let bodySizeStr = displayPrefs.bodySpecs.size {
            if let bodySize = Int(bodySizeStr) {
                css.append("\nh1 { font-weight: 600; font-size: \(bodySize+4)pt }")
                css.append("\nh2 { font-weight: 600; font-size: \(bodySize+2)pt }")
                css.append("\nh3 { font-weight: 600; font-size: \(bodySize+2)pt }")
                css.append("\nh4 { font-weight: 600; font-size: \(bodySize)pt }")
            }
        }
        code.startDoc(withTitle: docTitle, withCSS: css)
        code.heading(level: 1, text: docTitle)
        
        if let newsURL = Bundle.main.url(forResource: "notenik-news", withExtension: "html") {
            if let news = try? String(contentsOf: newsURL) {
                code.append(news)
            }
        }
        
        code.finishDoc()
        let html = String(describing: code)
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
    
    /// Handle a link when it is clicked.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let urlStr = url.absoluteString
        if urlStr.starts(with: "http") {
            let ok = NSWorkspace.shared.open(url)
            if ok {
                decisionHandler(.cancel)
                return
            } else {
                communicateError("Could not open the requested url: \(url.absoluteString)", alert: true)
            }
        }
        decisionHandler(.allow)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NewsViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
    
}

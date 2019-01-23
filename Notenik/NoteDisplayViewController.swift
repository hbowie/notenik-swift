//
//  NoteDisplayViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa
import WebKit

class NoteDisplayViewController: NSViewController, WKUIDelegate {

    @IBOutlet var webView: WKWebView!
    
    override func loadView() {
        webView = WKWebView()
        webView.uiDelegate = self
        view = webView
        print ("Note Display load view completed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print ("Note Display view did load")
        // Do view setup here.
    }
    
    func noteSelected(_ note: Note) {
        print ("Note Display note Selected")
        print ("title = \(note.title.value)")
        var html = "<html><body><p>" + note.title.value + "</p></body></html>"
        // let url = URL(string: "https://practopians.org")!
        // webView.load(URLRequest(url: url))
        let nav = webView.loadHTMLString(html, baseURL: nil)
        if nav == nil {
            print ("load html String returned nil")
        }
    }
    
}

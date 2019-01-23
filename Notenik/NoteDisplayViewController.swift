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
    
    let noteToHTML = NoteToHTML()
    
    // override func loadView() {
        // webView = WKWebView()
        
        // view = webView
        // print ("Note Display load view completed")
    // }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        // Do view setup here.
    }
    
    func noteSelected(_ note: Note) {
        print ("Note Display note Selected")
        print ("title = \(note.title.value)")
        let html = noteToHTML.getHTML(from: note)
        // let url = URL(string: "https://practopians.org")!
        // webView.load(URLRequest(url: url))
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            print ("load html String returned nil")
        }
        // webView.reload()
    }
    
}

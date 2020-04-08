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

import NotenikUtils

class NoteDisplayViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    var wc: CollectionWindowController?
    
    @IBOutlet var webView: WKWebView!
    
    let urlNavPrevix = "https://ntnk.app/"
    var bundlePrefix = ""
    
    let noteDisplay = NoteDisplay()
    
    var io: NotenikIO?
    var note: Note?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        bundlePrefix = Bundle.main.bundleURL.absoluteString + "#"
    }
    
    /// Display the provided note
    func display(note: Note, io: NotenikIO) {
        self.io = io
        self.note = note
        display()
    }
    
    /// Reload the Note's HTML when user requests this from Toolbar button.
    /// This can be helpful after the user has clicked on a link in the Note's display,
    /// to get back to the original display of the Note.
    func reload() {
        display()
    }
    
    /// Generate the display from the last note provided
    func display() {
        guard note != nil else { return }
        guard io != nil else { return }
        let html = noteDisplay.display(note!, io: io!)
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "NoteDisplayViewController",
                              level: .error,
                              message: "load html String returned nil")
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
        var notePath = ""
        if url.starts(with: urlNavPrevix) {
            notePath = String(url.dropFirst(urlNavPrevix.count))
        } else if url.starts(with: bundlePrefix) {
            notePath = String(url.dropFirst(bundlePrefix.count))
        } else {
            decisionHandler(.allow)
            return
        }
        let noteID = StringUtils.toCommon(String(notePath))
        guard let io = wc?.notenikIO else {
            decisionHandler(.cancel)
            return
        }
        var nextNote = io.getNote(forID: noteID)
        if nextNote == nil {
            nextNote = io.getNote(forTimestamp: noteID)
        }
        if nextNote == nil {
            // print("---- Linked Note not found")
        } else {
            wc!.select(note: nextNote, position: nil, source: .nav)
        }
        decisionHandler(.cancel)

    }
    
}

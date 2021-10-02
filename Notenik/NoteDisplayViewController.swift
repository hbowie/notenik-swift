//
//  NoteDisplayViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019-2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import WebKit

import NotenikUtils
import NotenikLib
import NotenikMkdown

class NoteDisplayViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    
    var wc: CollectionWindowController?
    
    var _countsVC: CountsViewController?
    
    var countsVC: CountsViewController? {
        set {
            _countsVC = newValue
            if _countsVC != nil {
                _countsVC?.updateCounts(counts)
            }
        }
        get {
            return _countsVC
        }
    }
    
    var webView: NoteDisplayWebView!
    var webConfig: WKWebViewConfiguration!
    
    let noteDisplay = NoteDisplay()
    
    var io: NotenikIO?
    var note: Note?
    var searchPhrase: String?
    
    var counts = MkdownCounts()
    
    var parms = DisplayParms()
    
    override func loadView() {
        webConfig = WKWebViewConfiguration()
        webView = NoteDisplayWebView(frame: .zero, configuration: webConfig)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        parms.localMj = true
        parms.localMjUrl = Bundle.main.url(forResource: "MathJax/es5/tex-mml-chtml",
                                           withExtension: "js")
        if parms.localMjUrl == nil {
            communicateError("Couldn't get a local MathJax URL")
        } 
    }
    
    /// Display the provided note
    func display(note: Note, io: NotenikIO, searchPhrase: String? = nil) {
        self.io = io
        self.note = note
        self.searchPhrase = searchPhrase
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
        webLinkFollowed(false)
        guard note != nil else { return }
        guard io != nil else { return }
        guard isViewLoaded else { return }
        
        parms.setFrom(note: note!)
        
        let (displayHTML, wikiAdds) = noteDisplay.display(note!, io: io!, parms: parms)
        var html = ""
        if searchPhrase == nil || searchPhrase!.isEmpty {
            html = displayHTML
        } else {
            html = StringUtils.highlightPhraseInHTML(phrase: searchPhrase!,
                                                     html: displayHTML,
                                                     klass: "search-results")
        }
        counts = noteDisplay.counts
        if countsVC != nil {
            countsVC!.updateCounts(counts)
        }
        // let baseURL = io!.collection!.lib.getURL(type: .notes)
        var nav: WKNavigation?
        nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        /* if baseURL != nil {
            nav = webView.loadHTMLString(html, baseURL: baseURL!)
        } else {
            nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        } */
        if nav == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "NoteDisplayViewController",
                              level: .error,
                              message: "load html String returned nil")
        }
        
        if wikiAdds && wc != nil {
            wc!.reloadViews()
        }
        
        // This is just a convenient spot to request that we refresh our
        // collective idea of what today is. 
        DateUtils.shared.refreshToday()
    }
    
    /// This method gets called when the user requests to open a link in a new window.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            return nil
        }
        
        guard wc != nil else {
            return nil
        }
        
        wc!.launchLink(url: url)
        
        return nil
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            webLinkFollowed(true)
            decisionHandler(.allow)
            return
        }
        
        guard wc != nil else {
            webLinkFollowed(true)
            decisionHandler(.allow)
            return
        }
        
        guard navigationAction.targetFrame != nil else {
            wc!.launchLink(url: url)
            webLinkFollowed(false)
            decisionHandler(.cancel)
            return
        }
        
        /// Figure out how to handle this sort of URL.
        let link = NotenikLink(url: url)
        
        switch link.type {
        case .weblink, .aboutlink:
            if String(describing: url) == "about:blank" {
                webLinkFollowed(false)
            } else {
                webLinkFollowed(true)
            }
            decisionHandler(.allow)
        case .notenikApp, .xcodeDev:
            webLinkFollowed(false)
            decisionHandler(.allow)
        case .wikiLink:
            let io = wc?.notenikIO
            var nextNote = io!.getNote(forID: link.noteID)
            if nextNote == nil {
                nextNote = io!.getNote(forID: (link.noteID + "s"))
            }
            if nextNote == nil {
                nextNote = io!.getNote(forTimestamp: link.noteID)
            }
            if nextNote == nil {
                webLinkFollowed(true)
                decisionHandler(.allow)
                return
            } else {
                webLinkFollowed(false)
                decisionHandler(.cancel)
                wc!.select(note: nextNote, position: nil, source: .action, andScroll: true)
            }
        default:
            wc!.launchLink(url: url)
            webLinkFollowed(false)
            decisionHandler(.cancel)
        }
    }
    
    func webLinkFollowed(_ followed: Bool) {
        guard let controller = wc else { return }
        controller.webLinkFollowed = followed
    }
    
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NoteDisplayViewController",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NoteDisplayViewController",
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

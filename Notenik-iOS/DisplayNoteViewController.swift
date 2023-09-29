//
//  DisplayNoteViewController.swift
//  Notenik-iOS
//
//  Created by Herb Bowie on 2/24/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import UIKit
import WebKit

import NotenikLib
import NotenikUtils
import NotenikMkdown

/// Display one selected Note from within the Collection. 
class DisplayNoteViewController: UIViewController, WKNavigationDelegate {
    
    var viewReady = false
    
    let noteDisplay = NoteDisplay()
    
    var webConfig: WKWebViewConfiguration!
    var webView:   WKWebView!
    
    var webLinkFollowed = false
    
    var notenikIO: NotenikIO?
    
    var _note: Note?
    var note: Note? {
        get {
            return _note
        }
        set {
            _note = newValue
            if _note != nil {
                displayNote(_note!)
            }
        }
    }
    
    override func loadView() {
        webConfig = WKWebViewConfiguration()
        webConfig.dataDetectorTypes = [.all]
        webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.allowsBackForwardNavigationGestures = true
        // webView.scrollView.isScrollEnabled = true
        // webView.scrollView.showsVerticalScrollIndicator = true
        self.view = webView
        // self.view.addSubview(webView)
        webView.navigationDelegate = self
        viewReady = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if _note != nil {
            displayNote(_note!)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        /// Make sure we have the objects we need in order to proceed.
        guard let url = navigationAction.request.url else {
            webLinkFollowed = true
            decisionHandler(.allow)
            return
        }
        
        guard viewReady else {
            webLinkFollowed = true
            decisionHandler(.allow)
            return
        }
        
        /* guard navigationAction.targetFrame != nil else {
            wc!.launchLink(url: url)
            webLinkFollowed = false
            decisionHandler(.cancel)
            return
        } */
        
        guard notenikIO != nil else {
            decisionHandler(.allow)
            return
        }
        
        /// Figure out how to handle this sort of URL.
        let link = NotenikLink(url: url)
        
        switch link.type {
        case .weblink, .aboutlink:
            // webLinkFollowed = true
            // decisionHandler(.allow)
            UIApplication.shared.open(url)
            webLinkFollowed = false
            decisionHandler(.cancel)
        case .notenikApp, .xcodeDev:
            webLinkFollowed = false
            decisionHandler(.allow)
        case .wikiLink:
            var nextNote = notenikIO!.getNote(forID: link.noteID)
            if nextNote == nil {
                nextNote = notenikIO!.getNote(forTimestamp: link.noteID)
            }
            if nextNote == nil {
                webLinkFollowed = true
                decisionHandler(.allow)
                return
            } else {
                decisionHandler(.cancel)
                displayNote(nextNote!)
            }
        default:
            webLinkFollowed = false
            decisionHandler(.allow)
        // default:
            // UIApplication.shared.open(url)
            // webLinkFollowed = false
            // decisionHandler(.cancel)
        }
    }
    
    func displayNote(_ dNote: Note) {
        
        webLinkFollowed = false
        guard viewReady else { return }
        guard let io = notenikIO else { return }
        let parms = DisplayParms()
        parms.setFrom(note: dNote)
        let results = TransformMdResults()
        webView.loadHTMLString(noteDisplay.display(dNote, io: io, parms: parms, mdResults: results), baseURL: io.collection!.fullPathURL)
    }

}

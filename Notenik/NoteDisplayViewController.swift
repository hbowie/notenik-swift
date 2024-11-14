//
//  NoteDisplayViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/21/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
@preconcurrency import WebKit

import NotenikUtils
import NotenikLib
import NotenikMkdown

class NoteDisplayViewController: NSViewController, 
                                    CollectionView,
                                    WKUIDelegate,
                                    WKNavigationDelegate,
                                    WKScriptMessageHandler {
    
    var wc: CollectionWindowController?
    
    var _countsVC: CountsViewController?
    
    var countsVC: CountsViewController? {
        set {
            _countsVC = newValue
            if _countsVC != nil {
                _countsVC?.updateCounts(mdResults.counts)
            }
        }
        get {
            return _countsVC
        }
    }
    
    var stackView: NSStackView!
    var webView: NoteDisplayWebView!
    var webConfig: WKWebViewConfiguration!
    var userContentController: WKUserContentController!
    var dataStore: WKWebsiteDataStore?
    
    let noteDisplay = NoteDisplay()
    
    var io: NotenikIO?
    var note: Note?
    var searchPhrase: String?
    
    var mdResults = TransformMdResults()
    
    var parms = DisplayParms()
    
    /// Set up the view for this controller.
    override func loadView() {
        
        super.loadView()
        stackView = NSStackView()
        stackView.orientation = .vertical
        
        // Initialize WebKit stuff
        webConfig = WKWebViewConfiguration()
        let webPrefs = WKPreferences()
        webPrefs.javaScriptEnabled = true
        if #available(macOS 11.0, *) {
            webConfig.limitsNavigationsToAppBoundDomains = false
        }
        webConfig.preferences = webPrefs
        // userContentController = WKUserContentController()
        userContentController = webConfig.userContentController
        /*
        let javaScript = """
        function checkBoxClicked() {
            document.write("<p>checkBoxClicked</p>");
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.swiftVC) {
                window.webkit.messageHandlers.swiftVC.postMessage({
                    "message": "message"
                });
            }
        }
        """
        let script = WKUserScript(source: javaScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script) */
        userContentController.add(self, name: NotenikConstants.checkBoxMessageHandlerName)
        webConfig.userContentController = userContentController
        
        dataStore = WKWebsiteDataStore.nonPersistent()
        webConfig.websiteDataStore = dataStore!
        
        webView = NoteDisplayWebView(frame: .zero, configuration: webConfig)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        stackView.addArrangedSubview(webView)
        view = stackView
    }
    
    /// Now that the we know the view has loaded successfully...
    override func viewDidLoad() {
        super.viewDidLoad()
        parms.localMj = true
        parms.localMjUrl = Bundle.main.url(forResource: "MathJax/es5/tex-mml-chtml",
                                           withExtension: "js")
        if parms.localMjUrl == nil {
            communicateError("Couldn't get a local MathJax URL")
        }
    }
    
    /// Save any important info prior to the view's disappearance.
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let scroller = wc?.scroller {
            if note != nil {
                scroller.displayEnd(note: note!, webView: webView)
            }
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Compliance with CollectionView.
    //
    // -----------------------------------------------------------
    
    var viewID = "note-display"
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    func focusOn(initViewID: String, 
                 note: NotenikLib.Note?,
                 position: NotenikLib.NotePosition?,
                 io: NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        self.io = io
        self.note = note
        self.searchPhrase = searchPhrase
        display()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Method(s) to comply with WKScriptMessageHandler
    //
    // -----------------------------------------------------------
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let ckNote = note else {
            return
        }
        guard message.name == NotenikConstants.checkBoxMessageHandlerName else {
            return
        }
        if let msgDict = message.body as? [String: Any] {
            var ckBoxNum = -1
            var ckBoxState = ""
            if let checkBoxNumberStr = msgDict["checkBoxNumber"] as? String {
                if let checkBoxNumber = Int(checkBoxNumberStr) {
                    ckBoxNum = checkBoxNumber
                }
            }
            if let state = msgDict["checkBoxState"] as? String {
                ckBoxState = state
            }
            if ckBoxNum > 0 {
                let name = ckNote.checkBoxName(count: ckBoxNum)
                if ckBoxState == MkdownConstants.checked {
                    ckNote.checkBoxUpdates[name] = true
                } else if ckBoxState == MkdownConstants.unchecked {
                    ckNote.checkBoxUpdates[name] = false
                }
            }
        }
    }
    
    func loadResourcePagesForCollection(io: NotenikIO) {
        noteDisplay.loadResourcePagesForCollection(io: io, parms: parms)
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
        guard let collection = io!.collection else { return }
        if let filepath = note!.noteID.getFullPath(note: note!) {
            CollectionJuggler.shared.setLastSelection(title: note!.title.value,
                                                      link: note!.getNotenikLink(preferringTimestamp: true),
                                                      filepath: filepath,
                                                      wc: wc)
        }
        if collection.imgLocal {
            parms.imagesPath = NotenikConstants.filesFolderName
        }
            
        parms.setFrom(note: note!)
        parms.checkBoxMessageHandlerName = NotenikConstants.checkBoxMessageHandlerName
        
        mdResults = TransformMdResults()
        
        var imagePref: ImagePref = .light
        let appearance = view.effectiveAppearance
        if appearance.name.rawValue.lowercased().contains("dark") {
            imagePref = .dark
        } else {
            imagePref = .light
        }
        let displayHTML = noteDisplay.display(note!, io: io!, parms: parms, mdResults: mdResults, imagePref: imagePref)
        var html = ""
        if searchPhrase == nil || searchPhrase!.isEmpty {
            html = displayHTML
        } else {
            html = StringUtils.highlightPhraseInHTML(phrase: searchPhrase!,
                                                     html: displayHTML,
                                                     klass: "search-results")
        }
        if countsVC != nil {
            countsVC!.updateCounts(mdResults.counts)
        }
        
        // See if any derived Note fields need to be updated.
        if AppPrefs.shared.parseUsingNotenik && (collection.minutesToReadDef != nil || collection.wikilinksDef != nil || collection.backlinksDef != nil) {
            var modified = false
            let modNote = note!.copy() as! Note
            
            // See if Minutes to Read have changed.
            if collection.minutesToReadDef != nil {
                let newMinutes = MinutesToReadValue(with: mdResults.counts)
                let oldMinutes = modNote.getField(def: collection.minutesToReadDef!)
                if oldMinutes == nil || oldMinutes!.value != newMinutes {
                    let minutesField = NoteField(def: collection.minutesToReadDef!, value: newMinutes)
                    _ = modNote.setField(minutesField)
                    modified = true
                }
            }
            
            // See if extracted Wiki Links have changed.
            if collection.wikilinksDef != nil && !mdResults.wikiLinks.isEmpty {
                let newLinks = mdResults.wikiLinks.links
                let trans = Transmogrifier(io: io!)
                let mods = trans.updateLinks(for: modNote, links: newLinks)
                if mods {
                    modified = true
                }
            }
            
            if modified {
                let (updatedNote, _) = io!.modNote(oldNote: note!, newNote: modNote)
                if updatedNote == nil {
                    communicateError("Attempt to modify derived values failed")
                } else {
                    let displayHTML = noteDisplay.display(updatedNote!, io: io!, parms: parms, mdResults: mdResults, imagePref: imagePref)
                    if searchPhrase == nil || searchPhrase!.isEmpty {
                        html = displayHTML
                    } else {
                        html = StringUtils.highlightPhraseInHTML(phrase: searchPhrase!,
                                                                 html: displayHTML,
                                                                 klass: "search-results")
                    }
                    if countsVC != nil {
                        countsVC!.updateCounts(mdResults.counts)
                    }
                }
            }
        }
        
        var base: URL? = Bundle.main.bundleURL
        var nav: WKNavigation?
        var tempHTML = false
        if collection.imgLocal {
            if let lib = io?.collection?.lib {
                let imgFolder = lib.getResource(type: .notes)
                let tempURL = imgFolder.url!.appendingPathComponent(NotenikConstants.tempDisplayBase).appendingPathExtension(NotenikConstants.tempDisplayExt)
                do {
                    try html.write(to: tempURL, atomically: true, encoding: .utf8)
                    tempHTML = true
                    base = imgFolder.url!
                    nav = webView.loadFileURL(tempURL, allowingReadAccessTo: imgFolder.url!)
                } catch {
                    communicateError("Could not write html to temporary file")
                }
            }
        }
        
        if !tempHTML {
            nav = webView.loadHTMLString(html, baseURL: base)
        }
        if nav == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "NoteDisplayViewController",
                              level: .error,
                              message: "load html String returned nil")
        }
        
        if mdResults.wikiAdds && wc != nil {
            wc!.reloadViews()
            for link in mdResults.wikiLinks.links {
                if !link.targetFound {
                    if link.originalTarget.hasPath {
                        let (targetCollection, targetIO) = MultiFileIO.shared.provision(shortcut: link.originalTarget.path, inspector: nil, readOnly: false)
                        if targetCollection != nil {
                            let resolution = NoteLinkResolution(io: targetIO, linkText: link.originalTarget.pathSlashItem)
                            NoteLinkResolver.resolve(resolution: resolution)
                            if resolution.result == .resolved {
                                let collection2 = NoteLinkResolverCocoa.link(wc: wc!, resolution: resolution)
                                if collection2 != nil {
                                    // collection2!.reloadViews()
                                    collection2!.reloadCollection(self)
                                    collection2!.selectNoteTitled(link.bestTarget.item)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if let scroller = wc?.scroller {
            if note != nil {
                scroller.displayStart(note: note!, webView: webView)
            }
        }
        
        // This is just a convenient spot to request that we refresh our
        // collective idea of what today is. 
        DateUtils.shared.refreshToday()
    }
    
    func scroll() {
        if let scroller = wc?.scroller {
            if note != nil {
                scroller.displayStart(note: note!, webView: webView)
            }
        }
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
        case .notenikApp, .xcodeDev, .tempFile:
            webLinkFollowed(false)
            decisionHandler(.allow)
        case .wikiLink:
            var linkText = link.noteID
            if link.linkPart4 != nil {
                linkText = String(link.linkPart4!)
            }
            let resolution = NoteLinkResolution(io: wc?.notenikIO, linkText: linkText)
            NoteLinkResolver.resolve(resolution: resolution)
            if resolution.result == .resolved {
                webLinkFollowed(false)
                decisionHandler(.cancel)
                _ = NoteLinkResolverCocoa.link(wc: wc!, resolution: resolution)
            } else {
                webLinkFollowed(true)
                decisionHandler(.allow)
                return
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
    
    // -----------------------------------------------------------
    //
    // MARK: Utility methods.
    //
    // -----------------------------------------------------------
    
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

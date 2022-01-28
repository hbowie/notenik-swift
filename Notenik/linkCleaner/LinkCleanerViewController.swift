//
//  LinkCleanerViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class LinkCleanerViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var windowController: LinkCleanerWindowController?
    
    var collectionWC: CollectionWindowController?
    
    @IBOutlet var fromClipboardButton: NSButton!
    @IBOutlet var fromLinkFieldButton: NSButton!
    
    @IBOutlet var dirtyLinkView: NSTextView!
    @IBOutlet var cleanLinkView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }
    
    func passCollectionWindow(_ collectionWC: CollectionWindowController) {
        self.collectionWC = collectionWC
    }
    
    func initialSetup() {
        fromClipboardButton.state = .on
        var dirtyFound: Bool = getDirtyFromClipboard()
        if !dirtyFound {
            fromLinkFieldButton.state = .on
            dirtyFound = getDirtyFromNote()
        }
    }
    
    @IBAction func linkSourceChanged(_ sender: AnyObject) {
        if fromClipboardButton.state == .on {
            _ = getDirtyFromClipboard()
        } else {
            _ = getDirtyFromNote()
        }
    }
    
    func getDirtyFromClipboard() -> Bool {
        if let str = NSPasteboard.general.pasteboardItems?.first?.string(forType: .string) {
            dirtyToClean(dirty: str)
            return true
        }
        return false
    }
    
    func getDirtyFromNote() -> Bool {
        if let str = collectionWC?.getDirtyLink() {
            dirtyToClean(dirty: str)
            return true
        }
        return false
    }
    
    @IBAction func toClipboard(_ sender: Any) {
        let board = NSPasteboard.general
        board.clearContents()
        let str = cleanLinkView.string
        board.setString(str, forType: NSPasteboard.PasteboardType.string)
        application.stopModal(withCode: .cancel)
        windowController!.close()
    }
    
    @IBAction func toLinkField(_ sender: Any) {
        guard let collWC = collectionWC else { return }
        let str = cleanLinkView.string
        collWC.setCleanLink(str)
        application.stopModal(withCode: .cancel)
        windowController!.close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        application.stopModal(withCode: .cancel)
        windowController!.close()
    }
    
    func dirtyToClean(dirty: String) {
        dirtyLinkView.string = dirty
        let cleaned = cleanLink(dirty)
        cleanLinkView.string = cleaned
    }
    
    /// The following code is Copyright (c) 2021 Robb Knight and generously
    /// shared under the terms of the MIT License. Robb's original code
    /// can be found on GitHub at rknightuk/TrackerZapper.
    func cleanLink(_ item: String) -> String {
        
        if item.contains("<") { return item } // assume it's HTML and don't run it
    
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: item, options: [], range: NSRange(location: 0, length: item.utf16.count))

        // prefixes from various places including
        // https://github.com/newhouse/url-tracking-stripper/blob/master/assets/js/trackers.js
        let REMOVE = [
            "_bta_c",
            "_bta_tid",
            "_ga",
            "_hsenc",
            "_hsmi",
            "_ke",
            "_openstat",
            "dm_i",
            "ef_id",
            "epik",
            "fbclid",
            "gclid",
            "gclsrc",
            "gdffi",
            "gdfms",
            "gdftrk",
            "hsa_",
            "igshid",
            "matomo_",
            "mc_",
            "mkwid",
            "msclkid",
            "mtm_",
            "ns_",
            "oly_anon_id",
            "oly_enc_id",
            "otc",
            "pcrid",
            "piwik_",
            "pk_",
            "rb_clickid",
            "redirect_log_mongo_id",
            "redirect_mongo_id",
            "ref",
            "s_kwcid",
            "sb_referer_host",
            "soc_src",
            "soc_trk",
            "spm",
            "sr_",
            "srcid",
            "stm_",
            "trk_",
            "utm_",
            "vero_",
        ]

        var formatted = item

        for match in matches {
            guard let range = Range(match.range, in: item) else { continue }
            let url = item[range]
            let urlParts = url.components(separatedBy: "?")
            if (urlParts.indices.contains(1))
            {
                var params = urlParts[1].components(separatedBy: "&")
                for r in REMOVE {
                    params = params.filter { !$0.starts(with: r)}
                }
                let joinedParams = params.joined(separator: "&")
                
                var formattedUrl = "\(urlParts[0])?\(joinedParams)"
                if (joinedParams == "")
                {
                    formattedUrl = urlParts[0]
                }
                formatted = formatted.replacingOccurrences(of: url, with: formattedUrl)
            }
        }

        return formatted
    }
}

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

import NotenikLib
import NotenikUtils

class QueryOutputViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var source: TemplateOutputSource?
    
    var windowTitle = "Query Output"
    var htmlString = ""
    
    var refreshing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    public func supplySource(_ source: TemplateOutputSource) {
        self.source = source
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = self.view.window else {
            return
        }
        var windowPosition = ""
        let frame = window.frame
        windowPosition.append("\(frame.minX);")
        windowPosition.append("\(frame.minY);")
        windowPosition.append("\(frame.width);")
        windowPosition.append("\(frame.height);")
        AppPrefs.shared.queryOutputWindowNumbers = windowPosition
        if refreshing && source != nil {
            source!.refreshQuery()
        }
    }
    
    func loadHTMLString(_ string: String) {
        webView.loadHTMLString(string, baseURL: nil)
        htmlString = string
    }
    
    
    @IBAction func webPageAction(_ sender: Any) {
        if let actionButton = sender as? NSPopUpButton {
            switch actionButton.indexOfSelectedItem {
            case 1:
                saveToDisk()
            case 2:
                browse()
            case 3:
                saveAndBrowse()
            default:
                break
            }
        }
        refreshing = false
    }
    
    /// Option 1: Save file to disk, at location of user's choice.
    func saveToDisk() {
        if let savedURL = askUserForLocation() {
            _ = writeToDisk(diskURL: savedURL)
        }
    }
    
    /// Option 2: Save file to temp directory and request that it be opened by preferred Web browser.
    func browse() {
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                                        isDirectory: true)
        let tempFileURL = tempDirURL.appendingPathComponent(defaultFileName)
        let ok = writeToDisk(diskURL: tempFileURL)
        if ok {
            NSWorkspace.shared.open(tempFileURL)
        }
    }
    
    /// Option 3: Save file to dis, at location of user's choice, and then
    /// request that it be opened by preferred Web browser. 
    func saveAndBrowse() {
        if let savedURL = askUserForLocation() {
            let ok = writeToDisk(diskURL: savedURL)
            if ok {
                NSWorkspace.shared.open(savedURL)
            }
        }
    }
    
    func askUserForLocation() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.title = "Specify an Output File"
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = defaultFileName
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
    
    func writeToDisk(diskURL: URL) -> Bool {
        var ok = true
        do {
            try htmlString.write(to: diskURL, atomically: true, encoding: .utf8)
        } catch {
            Logger.shared.log(subsystem: "Notenik",
                              category: "QueryOutputViewController",
                              level: .error,
                              message: "Trouble writing HTML to disk file at \(diskURL)")
            ok = false
        }
        return ok
    }
    
    @IBAction func refreshReport(_ sender: Any) {
        refreshing = true
        guard let window = self.view.window else {
            return
        }
        window.close()
    }
    
    var defaultFileName: String {
        return "\(StringUtils.toCommonFileName(windowTitle)).html"
    }
    
}

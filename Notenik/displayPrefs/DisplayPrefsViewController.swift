//
//  DisplayPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import WebKit

import NotenikUtils
import NotenikMkdown
import NotenikLib

/// A Class to allow users to update their font preferences for the Notenik Display Tab
class DisplayPrefsViewController: NSViewController, NSComboBoxDataSource {
    
    var window: DisplayPrefsWindowController!
    
    var displayPrefs = DisplayPrefs.shared

    @IBOutlet var longListCheckBox: NSButton!
    
    @IBOutlet var fontComboBox: NSComboBox!
    
    let fonts = DisplayFontsDataSource()
    
    @IBOutlet var sizeComboBox: NSComboBox!
    
    var sizes: [String] = ["08", "10", "12", "14", "16", "18", "20", "24", "28", "36"]
    
    @IBOutlet var cssText: NSTextView!
    
    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longFontList = displayPrefs.longFontList
        fonts.useLongList(longFontList)
        if longFontList {
            longListCheckBox.state = .on
        } else {
            longListCheckBox.state = .off
        }
        
        fontComboBox.usesDataSource = true
        fontComboBox.dataSource = fonts
        fontComboBox.hasVerticalScroller = true
        fontComboBox.numberOfVisibleItems = 10
        fontComboBox.reloadData()
        
        _ = setSelectedFont(displayPrefs.font)
        
        sizeComboBox.usesDataSource = true
        sizeComboBox.dataSource = self
        sizeComboBox.hasVerticalScroller = true
        sizeComboBox.numberOfVisibleItems = 10
        sizeComboBox.reloadData()
  
        let defaultSize = displayPrefs.size
        var i = 0
        var found = false
        while i < sizes.count && !found {
            if defaultSize! == sizes[i] {
                found = true
                sizeComboBox.selectItem(at: i)
            } else if defaultSize! < sizes[i] {
                sizes.insert(defaultSize!, at: i)
                found = true
                sizeComboBox.reloadData()
                sizeComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            sizes.append(defaultSize!)
            sizeComboBox.reloadData()
            sizeComboBox.selectItem(at: i)
        }
        
        cssText.font = NSFont(name: "Menlo", size: 14)
        if displayPrefs.css == nil {
            cssText.string = ""
        } else {
            cssText.string = displayPrefs.css!
        }
        
        refreshSample(self)
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return sizes.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 else { return nil }
        guard index < sizes.count else { return nil }
        return sizes[index]
    }
    
    @IBAction func fontAdjusted(_ sender: Any) {
        displayPrefs.font = fontComboBox.stringValue
        buildCSS()
        refreshSample(sender)
    }
    
    @IBAction func sizeAdjusted(_ sender: Any) {
        displayPrefs.size = sizeComboBox.stringValue
        buildCSS()
        refreshSample(sender)
    }
    
    func buildCSS() {
        displayPrefs.buildCSS()
        if displayPrefs.css == nil {
            cssText.string = ""
        } else {
            cssText.string = displayPrefs.css!
        }
    }
    
    @IBAction func refreshSample(_ sender: Any) {
        let code = Markedup(format: .htmlDoc)
        if cssText.string != displayPrefs.css {
            displayPrefs.css = cssText.string
        }
        code.startDoc(withTitle: nil, withCSS: displayPrefs.bodyCSS)
        MkdownParser.markdownToMarkedup(markdown: "There is nothing worse than a brilliant image of a fuzzy concept.",
                                        wikiLinkLookup: nil, writer: code)
        code.finishDoc()
        let html = String(describing: code)
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                              category: "DisplayPrefsViewController",
                              level: .error,
                              message: "load html String returned nil")
        }
    }
    
    @IBAction func longListChecked(_ sender: NSButton) {
        let originalFont = fontComboBox.stringValue
        let longList = longListCheckBox.state == .on
        fonts.useLongList(longList)
        displayPrefs.longFontList = longList
        fontComboBox.reloadData()
        let newFontIndex = setSelectedFont(originalFont)
        let newFont = fonts.itemAt(newFontIndex)
        if newFont != nil && newFont != originalFont {
            displayPrefs.font = newFont!
            buildCSS()
            refreshSample(sender)
        }
    }
    
    func setSelectedFont(_ font: String) -> Int {
        var fontIndex = fonts.indexFor(font)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        let defaultFont = displayPrefs.setDefaultFont()
        fontIndex = fonts.indexFor(defaultFont)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        fontIndex = 0
        fontComboBox.selectItem(at: fontIndex)
        return fontIndex

    }
    
    @IBAction func okClicked(_ sender: Any) {
        displayPrefs.css = cssText.string
        window.close()
        displayPrefs.displayRefresh()
    }
    
}

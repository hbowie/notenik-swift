//
//  DisplayPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import WebKit

/// A Class to allow users to update their font preferences for the Notenik Display Tab
class DisplayPrefsViewController: NSViewController, NSComboBoxDataSource {
    
    var window: DisplayPrefsWindowController!
    
    var displayPrefs = DisplayPrefs.shared

    @IBOutlet var fontComboBox: NSComboBox!
    
    var fonts: [String] = [
        "American Typewriter",
        "Andale Mono",
        "Arial",
        "Avenir",
        "Avenir Next",
        "Baskerville",
        "Big Caslon",
        "Bookman",
        "Courier",
        "Courier New",
        "Futura",
        "Garamond",
        "Georgia",
        "Gill Sans",
        "Helvetica",
        "Helvetica Neue",
        "Hoefler Text",
        "Lucida Grande",
        "Menlo",
        "Palatino",
        "Tahoma",
        "Times",
        "Times New Roman",
        "Trebuchet",
        "Verdana"
    ]
    
    @IBOutlet var sizeComboBox: NSComboBox!
    
    var sizes: [String] = ["08", "10", "12", "14", "16", "18", "20", "24", "28", "36"]
    
    @IBOutlet var cssText: NSTextView!
    
    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fontComboBox.usesDataSource = true
        fontComboBox.dataSource = self
        fontComboBox.hasVerticalScroller = true
        fontComboBox.numberOfVisibleItems = 10
        fontComboBox.reloadData()
        
        let defaultFont = displayPrefs.font
        var i = 0
        var found = false
        while i < fonts.count && !found {
            if defaultFont! == fonts[i] {
                found = true
                fontComboBox.selectItem(at: i)
            } else if defaultFont! < fonts[i] {
                fonts.insert(defaultFont!, at: i)
                found = true
                fontComboBox.reloadData()
                fontComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            fonts.append(defaultFont!)
            fontComboBox.selectItem(at: i)
        }
        
        sizeComboBox.usesDataSource = true
        sizeComboBox.dataSource = self
        sizeComboBox.hasVerticalScroller = true
        sizeComboBox.numberOfVisibleItems = 10
        sizeComboBox.reloadData()
  
        let defaultSize = displayPrefs.size
        i = 0
        found = false
        while i < sizes.count && !found {
            if defaultSize! == sizes[i] {
                found = true
                sizeComboBox.selectItem(at: i)
            } else if defaultSize! < sizes[i] {
                fonts.insert(defaultSize!, at: i)
                found = true
                sizeComboBox.reloadData()
                sizeComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            sizes.append(defaultSize!)
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
        if comboBox == fontComboBox {
            return fonts.count
        } else {
            return sizes.count
        }
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox == fontComboBox {
            return fonts[index]
        } else {
            return sizes[index]
        }
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
        code.startDoc(withTitle: nil, withCSS: displayPrefs.css)
        code.append(markdown: "There is nothing worse than a brilliant image of a fuzzy concept.")
        code.finishDoc()
        let html = String(describing: code)
        let nav = webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        if nav == nil {
            Logger.shared.log(skip: false, indent: 0, level: LogLevel.moderate,
                              message: "load html String returned nil")
        }
    }
    
    @IBAction func okClicked(_ sender: Any) {
        displayPrefs.css = cssText.string
        window.close()
    }
    
}

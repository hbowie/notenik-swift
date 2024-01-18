//
//  DisplayPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
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
class DisplayPrefsViewController: NSViewController {
    
    @IBOutlet var centerHeadingsStartPopup: NSPopUpButton!
    @IBOutlet var centerHeadingsFinishPopup: NSPopUpButton!
    
    @IBOutlet var bodyButton: NSButton!
    @IBOutlet var headingsButton: NSButton!
    @IBOutlet var listButton: NSButton!
    
    var fontSpecs = FontSpecs(fontsFor: .body)
    
    var window: DisplayPrefsWindowController!
    
    var displayPrefs = DisplayPrefs.shared

    @IBOutlet var longListCheckBox: NSButton!
    
    @IBOutlet var fontComboBox: NSComboBox!
    
    let fonts = CocoaFontsDataSource()
    
    @IBOutlet var sizeComboBox: NSComboBox!
    
    let sizes = FontSizeDataSource()
    
    @IBOutlet var sizeUnitLabel: NSTextField!
    
    @IBOutlet var cssText: NSTextView!
    
    @IBOutlet var webView: WKWebView!
    
    var startingCSS = ""
    var latestCSS = ""
    
    var startingCenterHeadingStart = 0
    var latestCenterHeadingStart = 0
    
    var startingCenterHeadingFinish = 0
    var latestCenterHeadingFinish = 0
    
    var mkdownOptions = MkdownOptions()
    
    // -----------------------------------------------------------
    //
    // MARK: Initial Setup.
    //
    // -----------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let centerHeadingStart = displayPrefs.headingCenterStart
        startingCenterHeadingStart = centerHeadingStart
        latestCenterHeadingStart = centerHeadingStart
        centerHeadingsStartPopup.selectItem(at: centerHeadingStart)
        
        let centerHeadingFinish = displayPrefs.headingCenterFinish
        startingCenterHeadingFinish = centerHeadingFinish
        latestCenterHeadingFinish = centerHeadingFinish
        centerHeadingsFinishPopup.selectItem(at: centerHeadingFinish)
        
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
        
        sizeComboBox.usesDataSource = true
        sizeComboBox.dataSource = sizes
        sizeComboBox.hasVerticalScroller = true
        sizeComboBox.numberOfVisibleItems = 10
        sizeComboBox.reloadData()
        
        bodyButton.state = .on
        fontSpecs = displayPrefs.getSpecs(fontsFor: .body)
        sizes.setFontsFor(.body)
        
        setFontDisplay()
        
        cssText.font = NSFont(name: "Menlo", size: 14)
        if displayPrefs.fontCSS == nil {
            cssText.string = ""
        } else {
            cssText.string = displayPrefs.fontCSS!
            startingCSS = displayPrefs.fontCSS!
            latestCSS = displayPrefs.fontCSS!
        }
        
        refreshSample(self)
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Capture user changes to center headings fields.
    //
    // -----------------------------------------------------------
    
    @IBAction func centerHeadingStartAdjusted(_ sender: Any) {
        let start = centerHeadingsStartPopup.indexOfSelectedItem
        if start == 0 {
            centerHeadingsFinishPopup.selectItem(at: 0)
        } else if centerHeadingsFinishPopup.indexOfSelectedItem == 0 {
            centerHeadingsFinishPopup.selectItem(at: start)
        } else if centerHeadingsFinishPopup.indexOfSelectedItem < start {
            centerHeadingsFinishPopup.selectItem(at: start)
        }
        latestCenterHeadingStart = centerHeadingsStartPopup.indexOfSelectedItem
        latestCenterHeadingFinish = centerHeadingsFinishPopup.indexOfSelectedItem
    }
    
    @IBAction func centerHeadingFinishAdjustment(_ sender: Any) {
        let finish = centerHeadingsFinishPopup.indexOfSelectedItem
        if finish == 0 {
            centerHeadingsStartPopup.selectItem(at: 0)
        } else if centerHeadingsStartPopup.indexOfSelectedItem == 0 {
            centerHeadingsStartPopup.selectItem(at: 1)
        } else if finish < centerHeadingsStartPopup.indexOfSelectedItem {
            centerHeadingsStartPopup.selectItem(at: finish)
        }
        latestCenterHeadingStart = centerHeadingsStartPopup.indexOfSelectedItem
        latestCenterHeadingFinish = centerHeadingsFinishPopup.indexOfSelectedItem
    }
    
    // -----------------------------------------------------------
    //
    // MARK: See whether we're working with body or headings.
    //
    // -----------------------------------------------------------
    
    @IBAction func bodyOrHeadings(_ sender: Any) {
        
        // Save latest values before switching.
        fontSpecs.setLatestFont(userSpec: fontComboBox.stringValue)
        fontSpecs.setLatestSize(userSpec: sizeComboBox.stringValue)
        
        if bodyButton.state == .on {
            fontSpecs = displayPrefs.getSpecs(fontsFor: .body)
            sizes.setFontsFor(.body)
            sizeUnitLabel.stringValue = "pt"
            fonts.addSystemFont(false)
        } else if headingsButton.state == .on {
            fontSpecs = displayPrefs.getSpecs(fontsFor: .headings)
            sizes.setFontsFor(.headings)
            sizeUnitLabel.stringValue = "em"
            fonts.addSystemFont(false)
        } else if listButton.state == .on {
            fontSpecs = displayPrefs.getSpecs(fontsFor: .list)
            sizes.setFontsFor(.list)
            sizeUnitLabel.stringValue = "pt"
            fonts.addSystemFont(true)
        }
        fontComboBox.reloadData()
        setFontDisplay()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Adjust the view to match the latest values.
    //
    // -----------------------------------------------------------
    
    func setFontDisplay() {
        _ = setSelectedFont(fontSpecs.getLatestFont())
        _ = setSelectedSize(fontSpecs.getLatestSize())
    }
    
    func setSelectedFont(_ font: String) -> Int {
        var fontIndex = fonts.indexFor(font)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        let defaultFont = fontSpecs.setDefaultFont()
        fontIndex = fonts.indexFor(defaultFont)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        fontIndex = 0
        fontComboBox.selectItem(at: fontIndex)
        return fontIndex
    }
    
    func setSelectedSize(_ size: String) -> Int {
        var sizeIndex = sizes.indexFor(size)
        if sizeIndex >= 0 {
            sizeComboBox.selectItem(at: sizeIndex)
            return sizeIndex
        }
        
        let defaultSize = fontSpecs.setDefaultSize()
        sizeIndex = sizes.indexFor(defaultSize)
        if sizeIndex >= 0 {
            sizeComboBox.selectItem(at: sizeIndex)
            return sizeIndex
        }
        
        sizeIndex = 0
        sizeComboBox.selectItem(at: sizeIndex)
        return sizeIndex
    }
    
    @IBAction func fontAdjusted(_ sender: Any) {
        fontSpecs.setLatestFont(userSpec: fontComboBox.stringValue)
    }
    
    @IBAction func sizeAdjusted(_ sender: Any) {
        fontSpecs.setLatestSize(userSpec: sizeComboBox.stringValue)
    }
    
    @IBAction func generateCSSButtonPushed(_ sender: NSButton) {
        latestCSS = displayPrefs.bodySpecs.buildLatestCSS(indent: 0)
        cssText.string = latestCSS
        refreshSample(sender)
    }
    
    @IBAction func refreshSample(_ sender: Any) {
        if cssText.string != latestCSS {
            latestCSS = cssText.string
        }
        let code = Markedup(format: .htmlDoc)
        let css = displayPrefs.buildBodyCSS(latestCSS)
            + displayPrefs.buildHeadingCSS(centerStart: latestCenterHeadingStart,
                                           centerFinish: latestCenterHeadingFinish,
                                           bodyFont: displayPrefs.bodySpecs.getLatestFont(),
                                           headingsFont: displayPrefs.headingSpecs.getLatestFont(),
                                           headingsSize: displayPrefs.headingSpecs.getLatestSize())
        code.startDoc(withTitle: nil, withCSS: css)
        let md = """
        # Great Quotes (h1)
        
        ### by Ansel Adams (h3)
        
        There is nothing worse than a brilliant image of a fuzzy concept.
        
        """

        Markdown.markdownToMarkedup(markdown: md, options: mkdownOptions, mkdownContext: nil, writer: code)
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
            fontSpecs.font = newFont!
        }
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        window.close()
    }
    
    @IBAction func okClicked(_ sender: Any) {
        latestCenterHeadingStart = centerHeadingsStartPopup.indexOfSelectedItem
        latestCenterHeadingFinish = centerHeadingsFinishPopup.indexOfSelectedItem
        fontSpecs.setLatestFont(userSpec: fontComboBox.stringValue)
        fontSpecs.setLatestSize(userSpec: sizeComboBox.stringValue)
        latestCSS = cssText.string
        if latestCSS == startingCSS {
            if displayPrefs.bodySpecs.latestSpecsChanged {
                latestCSS = displayPrefs.bodySpecs.buildLatestCSS(indent: 0)
            }
        }
        displayPrefs.headingCenterStart = latestCenterHeadingStart
        displayPrefs.headingCenterFinish = latestCenterHeadingFinish
        displayPrefs.saveLatestFontSpecs()
        displayPrefs.fontCSS = latestCSS
        window.close()
        displayPrefs.displayRefresh()
    }
    
}

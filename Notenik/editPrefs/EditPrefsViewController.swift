//
//  EditPrefsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/20/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class EditPrefsViewController: NSViewController, NSComboBoxDataSource {
    
    let appPrefsCocoa = AppPrefsCocoa.shared
    
    var window: EditPrefsWindowController!

    @IBOutlet weak var labelsRadioButton: NSButton!
    @IBOutlet weak var textRadioButton:   NSButton!
    @IBOutlet weak var codeRadioButton:   NSButton!
    
    @IBOutlet weak var longListCheckBox:  NSButton!
    @IBOutlet weak var fontComboBox:      NSComboBox!
    @IBOutlet weak var sizeComboBox:      NSComboBox!
    @IBOutlet weak var sampleTextView:    NSTextView!
    
    var sizes: [String] = ["08", "09", "10", "11", "12", "13", "14", "15", "16", "18", "20", "22", "24"]
    
    let fonts = CocoaFontsDataSource()
    
    var labelFontPrefs = CocoaFontPrefs(.labels)
    var textFontPrefs  = CocoaFontPrefs(.text)
    var codeFontPrefs  = CocoaFontPrefs(.code)
    
    var selectedFontPrefs = CocoaFontPrefs(.text)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelFontPrefs = appPrefsCocoa.labelFontPrefs
        textFontPrefs  = appPrefsCocoa.textFontPrefs
        codeFontPrefs  = appPrefsCocoa.codeFontPrefs
        
        // Set up font sizes.
        sizeComboBox.usesDataSource = true
        sizeComboBox.dataSource = self
        sizeComboBox.hasVerticalScroller = true
        sizeComboBox.numberOfVisibleItems = 10
        sizeComboBox.reloadData()
        
        // Set up font names.
        fontComboBox.usesDataSource = true
        fontComboBox.dataSource = fonts
        fontComboBox.hasVerticalScroller = true
        fontComboBox.numberOfVisibleItems = 10
        fontComboBox.reloadData()
        
        textRadioButton.state = .on
        setFontUsage(.text)
        setFontPrefs()
    }
    
    @IBAction func textOrCode(_ sender: Any) {
        if labelsRadioButton.state == .on {
            setFontUsage(.labels)
        } else if textRadioButton.state == .on {
            setFontUsage(.text)
        } else {
            setFontUsage(.code)
        }
    }
    
    func setFontUsage(_ usage: CocoaFontUsage) {
        switch usage {
        case .labels:
            selectedFontPrefs = labelFontPrefs
        case .text:
            selectedFontPrefs = textFontPrefs
        case .code:
            selectedFontPrefs = codeFontPrefs
        }
        let fontIndex = fonts.indexFor(selectedFontPrefs.familyName)
        if fontIndex < 0 && longListCheckBox.state != .on {
            longListCheckBox.state = .on
            fonts.useLongList(true)
            fontComboBox.reloadData()
        }
        setFontPrefs()
    }
    
    /// Respond to user's selection of a long list of fonts vs. a short list of common font families.
    @IBAction func longListSelection(_ sender: Any) {
        let originalFont = fontComboBox.stringValue
        let longList = longListCheckBox.state == .on
        fonts.useLongList(longList)
        fontComboBox.reloadData()
        let newFontIndex = setSelectedFont(originalFont)
        let newFont = fonts.itemAt(newFontIndex)
        if newFont != nil && newFont != originalFont {
            _ = selectedFontPrefs.setFamily(from: newFont!)
        }
    }
    
    /// Attempt to select the specified font within the combo box.
    func setSelectedFont(_ font: String) -> Int {
        var fontIndex = fonts.indexFor(font)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        fontIndex = fonts.indexFor(selectedFontPrefs.defaultFamilyName)
        if fontIndex >= 0 {
            fontComboBox.selectItem(at: fontIndex)
            return fontIndex
        }
        
        fontIndex = 0
        fontComboBox.selectItem(at: fontIndex)
        return fontIndex
    }
    
    /// The user selected a specific font family.
    @IBAction func fontAdjusted(_ sender: Any) {
        let familyName = fontComboBox.stringValue
        _ = selectedFontPrefs.setFamily(from: familyName)
        setSelectedFont()
    }
    
    @IBAction func sizeAdjusted(_ sender: Any) {
        if selectedFontPrefs.setSize(from: sizeComboBox.stringValue) {
            setSelectedFont()
        }
    }
    
    func setFontPrefs() {
        setSelectedFont()
    }
    
    /// Set selected font size.
    func setSelectedFont() {
        let currSize = selectedFontPrefs.sizeAsString
        
        var i = 0
        var found = false
        while i < sizes.count && !found {
            if currSize == sizes[i] {
                found = true
                sizeComboBox.selectItem(at: i)
            } else if currSize < sizes[i] {
                sizes.insert(currSize, at: i)
                found = true
                sizeComboBox.reloadData()
                sizeComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            sizes.append(currSize)
            sizeComboBox.reloadData()
            sizeComboBox.selectItem(at: i)
        }
        
        i = 0
        found = false
        while i < fonts.numberOfItems && !found {
            if selectedFontPrefs.familyName == fonts.itemAt(i) {
                found = true
                fontComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        
        switch selectedFontPrefs.usage {
        case .labels:
            sampleTextView.string = "Body: "
            appPrefsCocoa.setLabelFont(object: sampleTextView)
        case .text:
            sampleTextView.string = "As we are increasingly coming to realize, our species does represent a new evolutionary process — cultural evolution — that far surpasses cultural traditions in other species."
            appPrefsCocoa.setTextEditingFont(object: sampleTextView)
        case .code:
            sampleTextView.string = "        if selectedFontPrefs.setSize(from: sizeComboBox.stringValue) {\n            setSelectedFont()\n        }"
            appPrefsCocoa.setCodeEditingFont(view: sampleTextView)
        }
  
    }
    
    @IBAction func cancel(_ sender: Any) {
        labelFontPrefs.loadDefaults()
        textFontPrefs.loadDefaults()
        codeFontPrefs.loadDefaults()
        window.close()
    }
    
    @IBAction func ok(_ sender: Any) {
        labelFontPrefs.saveDefaults()
        textFontPrefs.saveDefaults()
        codeFontPrefs.saveDefaults()
        window.close()
        CollectionJuggler.shared.adjustEditWindows()
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Act as data source for font size combo box. 
    //
    // -----------------------------------------------------------
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return sizes.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index >= 0 else { return nil }
        guard index < sizes.count else { return nil }
        return sizes[index]
    }
    
}

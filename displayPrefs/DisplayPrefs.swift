//
//  DisplayPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/8/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Singleton Class for sharing and updating appearance preferences for the Display tab
class DisplayPrefs {
    
    // Provide a single standard shared singleton instance
    static let shared = DisplayPrefs()
    
    let defaults = UserDefaults.standard
    
    let displayFontKey = "display-font"
    var _displayFont: String?
    let defaultFont = "Verdana"
    
    let displaySizeKey = "display-size"
    var _displaySize: String?
    let defaultSize = "12"
    
    let displayCSSKey = "display-css"
    var _displayCSS: String?
    
    /// Private initializer to prevent creation of more than one instance
    private init() {
        
        _displayFont = defaults.string(forKey: displayFontKey)
        if _displayFont == nil || _displayFont!.count == 0 {
            setDefaultFont()
        }
        
        _displaySize = defaults.string(forKey: displaySizeKey)
        if _displaySize == nil || _displaySize!.count == 0 {
            setDefaultSize()
        }
        
        _displayCSS = defaults.string(forKey: displayCSSKey)
        if _displayCSS == nil || _displayCSS!.count == 0 {
            setDefaultCSS()
        }
    }
    
    func setDefaults() {
        setDefaultFont()
        setDefaultSize()
        setDefaultCSS()
    }
    
    func setDefaultFont() {
        font = defaultFont
    }
    
    func setDefaultSize() {
        size = defaultSize
    }
    
    func setDefaultCSS() {
        buildCSS()
    }
    
    var font: String? {
        get {
            return _displayFont
        }
        set {
            _displayFont = newValue
            defaults.set(_displayFont, forKey: displayFontKey)
            buildCSS()
        }
    }
    
    var sizePlusUnit: String? {
        if _displaySize == nil {
            return nil
        } else {
            return _displaySize! + "pt"
        }
    }
    
    var size: String? {
        get {
            return _displaySize
        }
        set {
            _displaySize = newValue
            defaults.set(_displaySize, forKey: displaySizeKey)
            buildCSS()
        }
    }
    
    func buildCSS() {
        var tempCSS = ""
        tempCSS += "font-family: "
        if font == nil {
            setDefaultFont()
        }
        tempCSS += "\"" + font! + "\""
        tempCSS += ", \"Helvetica Neue\", Helvetica, Arial, sans-serif;\n"
        tempCSS += "font-size: "
        if size == nil {
            setDefaultSize()
        }
        tempCSS += sizePlusUnit!
        css = tempCSS
    }
    
    /// Apply the CSS to the entire body. 
    var bodyCSS: String? {
        var tempCSS = "body { "
        if css != nil {
            tempCSS.append(css!)
        }
        tempCSS.append(" }")
        return tempCSS
    }
    
    var css: String? {
        get {
            return _displayCSS
        }
        set {
            _displayCSS = newValue
            defaults.set(_displayCSS, forKey: displayCSSKey)
        }
    }
}

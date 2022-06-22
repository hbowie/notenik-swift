//
//  CocoaFontPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 6/21/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// An object containing font info for one particular category of usage.
class CocoaFontPrefs {
    
    let defaults = UserDefaults.standard
    
    let fontSizeKey       = "font-size"
    let fontFamilyKey     = "font-family"
    let defaultFontSize: Float = 13.0
    
    let sizeFormatter = NumberFormatter()
    
    var usage: CocoaFontUsage = .text
    
    var size:   Float   = 13.0
    var sizeCG: CGFloat = 13.0
    var sizeAsString    = "13"
    
    var familyName = ""
    
    var defaultFamilyName = "Helvetica"
    
    var font = NSFont.userFont(ofSize: 13.0)
    
    var fontAttrs = [NSAttributedString.Key.font: NSFont.userFont(ofSize: 13.0)]
    
    /// Create a new instance for the given usage.
    init(_ usage: CocoaFontUsage) {
        
        self.usage = usage
        
        sizeFormatter.minimumIntegerDigits = 2
        sizeFormatter.maximumFractionDigits = 0
        deriveFromSize()
        
        var defaultFont = NSFont.userFont(ofSize: sizeCG)
        switch usage {
        case .code:
            defaultFont = NSFont.userFixedPitchFont(ofSize: sizeCG)
        default:
            break
        }
        if let fam = defaultFont?.familyName {
            defaultFamilyName = fam
        }
        familyName = defaultFamilyName
        _ = deriveFromFamily()
    }
    
    /// Load the saved user preferences..
    func loadDefaults() {
        
        var preferredSize = defaults.float(forKey: fullKey(partialKey: fontSizeKey))
        
        if preferredSize == 0.0 {
            preferredSize = defaults.float(forKey: fontSizeKey)
        }
        
        if preferredSize > 0.1 {
            setSize(from: preferredSize)
        }
        
        if let preferredFamily = defaults.string(forKey: fullKey(partialKey: fontFamilyKey)) {
            familyName = preferredFamily
        }
        _ = deriveFromFamily()
    }
    
    func increaseFontSize(by: Float) {
        size += by
        deriveFromSize()
    }
    
    public func decreaseFontSize(by: Float) {
        size -= by
        deriveFromSize()
    }
    
    public func resetEditFontSize() {
        size = defaultFontSize
        deriveFromSize()
    }
    
    func setSize(from: String) -> Bool {
        if let float = Float(from) {
            size = float
            deriveFromSize()
            return true
        }
        return false
    }
    
    func setSize(from: Float) {
        size = from
        deriveFromSize()
    }
    
    /// Size has been set -- calculate derived fields.
    func deriveFromSize() {
        
        sizeCG = CGFloat(size)
        
        let num = NSNumber(value: size)
        if let str = sizeFormatter.string(from: num) {
            sizeAsString = str
        } else {
            sizeAsString = "13"
        }
        
        _ = deriveFont()
    }
    
    func setFamily(from: String) -> Bool {
        familyName = from
        return deriveFromFamily()
    }
    
    /// Family has been set -- calculate derived fields.
    func deriveFromFamily() -> Bool {
        return deriveFont()
    }
    
    /// Create the appropriate Font, based on previously set font name and size.
    func deriveFont() -> Bool {
        var validFont = false
        if let possibleFont = NSFont(name: familyName, size: sizeCG) {
            font = possibleFont
            validFont = true
        }
        fontAttrs = [NSAttributedString.Key.font: font]
        return validFont
    }
    
    
    /// Save the user preferences for later use.
    func saveDefaults() {
        defaults.set(size, forKey: fullKey(partialKey: fontSizeKey))
        defaults.set(familyName, forKey: fullKey(partialKey: fontFamilyKey))
    }
    
    func fullKey(partialKey: String) -> String {
        return usage.rawValue + "-" + partialKey
    }
    
}

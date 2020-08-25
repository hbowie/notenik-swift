//
//  AppPrefsCocoa.swift
//  Notenik
//
//  Created by Herb Bowie on 8/24/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class AppPrefsCocoa {
    
    /// Provide a standard shared singleton instance
    static let shared = AppPrefsCocoa()
    
    let defaults = UserDefaults.standard
    
    let launchingKey    = "app-launching"
    let fontSizeKey     = "font-size"
    
    var _edFS:   Float   = 13.0
    var _edFSCG: CGFloat = 13.0
    
    var userFont       = NSFont.userFont(ofSize: 13.0)
    var fixedPitchFont = NSFont.userFixedPitchFont(ofSize: 13.0)
    
    var userFontAttrs       = [NSAttributedString.Key.font: NSFont.userFont(ofSize: 13.0)]
    var fixedPitchFontAttrs = [NSAttributedString.Key.font: NSFont.userFixedPitchFont(ofSize: 13.0)]
    
    var editFontSize: Float {
        get {
            return _edFS
        }
        set {
            if newValue > 8.0 && newValue < 24.0 {
                _edFS = newValue
                defaults.set(_edFS, forKey: fontSizeKey)
                deriveRelatedFontFields()
            }
        }
    }
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        loadDefaults()
    }
    
    func resetDefaults() {
        resetEditFontSize()
        deriveRelatedFontFields()
    }
    
    func loadDefaults() {
        
        let defaultFontSize = defaults.float(forKey: fontSizeKey)
        if defaultFontSize == 0.0 {
            defaults.set(_edFS, forKey: fontSizeKey)
        } else {
            _edFS = defaultFontSize
        }
        deriveRelatedFontFields()
        
    }
    
    /// Prepare all the font fields we might need, adjusted to the latest size selection
    func deriveRelatedFontFields() {
        
        _edFSCG = CGFloat(_edFS)
        
        userFont = NSFont.userFont(ofSize: _edFSCG)
        fixedPitchFont = NSFont.userFixedPitchFont(ofSize: _edFSCG)
        
        userFontAttrs = [NSAttributedString.Key.font: userFont]
        fixedPitchFontAttrs = [NSAttributedString.Key.font: fixedPitchFont]
    }
    
    public func increaseEditFontSize(by: Float) {
        editFontSize += by
    }
    
    public func decreaseEditFontSize(by: Float) {
        editFontSize -= by
    }
    
    public func resetEditFontSize() {
        editFontSize = 13.0
    }
    
    public func setRegularFont(object: NSObject) {
        if userFont != nil {
            if let cb = object as? NSComboBox {
                cb.font = userFont
            } else if let textView = object as? NSTextView {
                textView.font = userFont
            } else if let textField = object as? NSTextField {
                textField.font = userFont
            } else if let menu = object as? NSMenu {
                menu.font = userFont
            }
        }
    }
    
    public func setFixedPitchFont(view: NSView) {
        if userFont != nil {
            if let textView = view as? NSTextView {
                textView.font = fixedPitchFont
            } else if let textField = view as? NSTextField {
                textField.font = fixedPitchFont
            }
        }
    }
    
    /// Make an attributed string using latest font size
    public func makeUserAttributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: userFontAttrs as [NSAttributedString.Key: Any])
    }
    
    /// Determine the appropriate height constraint for a text view based on the desired
    /// Number of lines to show.
    public func getViewHeight(lines: Float) -> CGFloat {
        return CGFloat(editFontSize * 1.20 * lines)
    }
}

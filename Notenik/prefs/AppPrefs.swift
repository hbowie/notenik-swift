//
//  AppPrefs.swift
//  Notenik
//
//  Created by Herb Bowie on 5/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Act as an intermediary between various Application classes and the UserDefaults
class AppPrefs {
    
    /// Provide a standard shared singleton instance
    static let shared = AppPrefs()
    
    let defaults = UserDefaults.standard
    
    let quickDeletesKey = "quick-deletes"
    let fontSizeKey     = "font-size"
    let tagsSelectKey   = "tags-to-select"
    let tagsSuppressKey = "tags-to-suppress"
    let parentRealmParentKey = "parent-realm-parent"
    
    var _qd: Bool = false
    
    var _edFS:   Float   = 13.0
    var _edFSCG: CGFloat = 13.0
    
    var _prp = ""
    var parentRealmPath = ""
    
    var userFont       = NSFont.userFont(ofSize: 13.0)
    var fixedPitchFont = NSFont.userFixedPitchFont(ofSize: 13.0)
    
    var userFontAttrs       = [NSAttributedString.Key.font: NSFont.userFont(ofSize: 13.0)]
    var fixedPitchFontAttrs = [NSAttributedString.Key.font: NSFont.userFixedPitchFont(ofSize: 13.0)]
    
    var pickLists = ValuePickLists()
    
    var _tsel = ""
    var _tsup = ""
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        
        _qd = defaults.bool(forKey: quickDeletesKey)
        
        let defaultFontSize = defaults.float(forKey: fontSizeKey)
        if defaultFontSize == 0.0 {
            defaults.set(_edFS, forKey: fontSizeKey)
        } else {
            _edFS = defaultFontSize
        }
        deriveRelatedFontFields()
        
        let tsel = defaults.string(forKey: tagsSelectKey)
        if tsel != nil {
            _tsel = tsel!
        }
        let tsup = defaults.string(forKey: tagsSuppressKey)
        if tsup != nil {
            _tsup = tsup!
        }
        
        let defaultprp = defaults.string(forKey: parentRealmParentKey)
        if defaultprp != nil {
            _prp = defaultprp!
        }
    }
    
    var confirmDeletes: Bool {
        get {
            return !_qd
        }
        set {
            _qd = !newValue
            defaults.set(_qd, forKey: quickDeletesKey)
        }
    }
    
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
    
    var parentRealmParent: String {
        get {
            return _prp
        }
        set {
            _prp = newValue
            defaults.set(_prp, forKey: parentRealmParentKey)
        }
    }
    
    var parentRealmParentURL: URL? {
        get {
            if _prp.count > 0 {
                return URL(fileURLWithPath: _prp)
            } else {
                return nil
            }
        }
        set {
            if newValue != nil {
                _prp = newValue!.path
                defaults.set(_prp, forKey: parentRealmParentKey)
            }
        }
    }
    
    /// Prepare all the font fields we might need, adjusted to the latest size selection
    func deriveRelatedFontFields() {
        
        _edFSCG = CGFloat(_edFS)
        
        userFont = NSFont.userFont(ofSize: _edFSCG)
        fixedPitchFont = NSFont.userFixedPitchFont(ofSize: _edFSCG)
        
        userFontAttrs = [NSAttributedString.Key.font: userFont]
        fixedPitchFontAttrs = [NSAttributedString.Key.font: fixedPitchFont]
    }
    
    func increaseEditFontSize(by: Float) {
        editFontSize += by
    }
    
    func decreaseEditFontSize(by: Float) {
        editFontSize -= by
    }
    
    func resetEditFontSize() {
        editFontSize = 13.0
    }
    
    func setRegularFont(object: NSObject) {
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
    
    func setFixedPitchFont(view: NSView) {
        if userFont != nil {
            if let textView = view as? NSTextView {
                textView.font = fixedPitchFont
            } else if let textField = view as? NSTextField {
                textField.font = fixedPitchFont
            }
        }
    }
    
    /// Make an attributed string using latest font size
    func makeUserAttributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string: text, attributes: userFontAttrs as [NSAttributedString.Key: Any])
    }
    
    /// Determine the appropriate height constraint for a text view based on the desired
    /// Number of lines to show. 
    func getViewHeight(lines: Float) -> CGFloat {
        return CGFloat(editFontSize * 1.20 * lines)
    }
    
    var tagsToSelect: String {
        get {
            return _tsel
        }
        set {
            _tsel = newValue
            defaults.set(_tsel, forKey: tagsSelectKey)
        }
    }
    
    var tagsToSuppress: String {
        get {
            return _tsup
        }
        set {
            _tsup = newValue
            defaults.set(_tsup, forKey: tagsSuppressKey)
        }
    }
}

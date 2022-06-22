//
//  AppPrefsCocoa.swift
//  Notenik
//
//  Created by Herb Bowie on 8/24/20.
//  Copyright © 2020 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// A shared object used to apply a standard look to cocoa controls.
class AppPrefsCocoa {
    
    /// Provide a standard shared singleton instance
    static let shared = AppPrefsCocoa()
    
    let defaults = UserDefaults.standard
    
    var labelFontPrefs = CocoaFontPrefs(.labels)
    var textFontPrefs  = CocoaFontPrefs(.text)
    var codeFontPrefs  = CocoaFontPrefs(.code)
    
    /// Private initializer to enforce usage of the singleton instance
    private init() {
        loadDefaults()
    }
    
    func resetDefaults() {
        resetEditFontSize()
    }
    
    func loadDefaults() {
        labelFontPrefs.loadDefaults()
        textFontPrefs.loadDefaults()
        codeFontPrefs.loadDefaults()
    }
    
    public func increaseEditFontSize(by: Float) {
        labelFontPrefs.increaseFontSize(by: by)
        textFontPrefs.increaseFontSize(by: by)
        codeFontPrefs.increaseFontSize(by: by)
    }
    
    public func decreaseEditFontSize(by: Float) {
        labelFontPrefs.decreaseFontSize(by: by)
        textFontPrefs.decreaseFontSize(by: by)
        codeFontPrefs.decreaseFontSize(by: by)
    }
    
    public func resetEditFontSize() {
        labelFontPrefs.resetEditFontSize()
        textFontPrefs.resetEditFontSize()
        codeFontPrefs.resetEditFontSize()
    }
    
    public func setLabelFont(object: NSObject) {
        if let textField = object as? NSTextField {
            textField.font = labelFontPrefs.font
        }
    }
    
    public func setTextEditingFont(object: NSObject) {

        if let cb = object as? NSComboBox {
            cb.font = textFontPrefs.font
        } else if let textView = object as? NSTextView {
            textView.font = textFontPrefs.font
        } else if let textField = object as? NSTextField {
            textField.font = textFontPrefs.font
        } else if let menu = object as? NSMenu {
            menu.font = textFontPrefs.font
        }
    }
    
    public func setCodeEditingFont(view: NSView) {

        if let textView = view as? NSTextView {
            textView.font = codeFontPrefs.font
        } else if let textField = view as? NSTextField {
            textField.font = codeFontPrefs.font
        }
    }
    
    /// Make an attributed string using latest font size
    public func makeUserAttributedString(text: String, usage: CocoaFontUsage) -> NSAttributedString {
        switch usage {
        case .labels:
            return NSAttributedString(string: text, attributes: labelFontPrefs.fontAttrs as [NSAttributedString.Key: Any])
        case .text:
            return NSAttributedString(string: text, attributes: textFontPrefs.fontAttrs as [NSAttributedString.Key: Any])
        case .code:
            return NSAttributedString(string: text, attributes: codeFontPrefs.fontAttrs as [NSAttributedString.Key: Any])
        }
    }
    
    /// Determine the appropriate height constraint for a text view based on the desired
    /// Number of lines to show.
    public func getViewHeight(lines: Float) -> CGFloat {
        return CGFloat(textFontPrefs.size * 1.20 * lines)
    }
    
    public func saveDefaults() {
        labelFontPrefs.saveDefaults()
        textFontPrefs.saveDefaults()
        codeFontPrefs.saveDefaults()
    }
}

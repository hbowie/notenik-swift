//
//  LongTextView.swift
//  Notenik
//
//  Created by Herb Bowie on 3/29/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class LongTextView: MacEditView {
    
    var scrollView: NSScrollView!
    var textView: NSTextView!
    
    var view: NSView {
        return scrollView
    }
    
    var text: String {
        get {
            return textView.string
        }
        set {
            textView.string = newValue
        }
    }
    
    init() {
        buildView()
    }
    
    func buildView() {
        
        // Set up the Scroll View
        let scrollRect = NSRect(x: 0, y: 0, width: 300, height: 150)
        scrollView = NSScrollView(frame: scrollRect)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        let height = AppPrefsCocoa.shared.getViewHeight(lines: 5.0)
        scrollView.heightAnchor.constraint(equalToConstant: height).isActive = true
        scrollView.borderType = .bezelBorder
        
        // Set up the Text View
        let contentSize = scrollView.contentSize
        let textRect = NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        textView = NSTextView(frame: textRect)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: 32000, height: 32000)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer!.containerSize = NSSize(width: contentSize.width, height: 32000)
        textView.textContainer!.widthTracksTextView = true
        
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.allowsUndo = true
        if textView.isAutomaticDashSubstitutionEnabled {
            textView.toggleAutomaticDashSubstitution(nil)
        }
        if textView.isAutomaticQuoteSubstitutionEnabled {
            textView.toggleAutomaticQuoteSubstitution(nil)
        }
        if #available(OSX 10.12.2, *) {
            if textView.isAutomaticTextCompletionEnabled {
                textView.toggleAutomaticTextCompletion(nil)
            }
        } 
        if textView.isAutomaticSpellingCorrectionEnabled {
            textView.toggleAutomaticSpellingCorrection(nil)
        }
        
        AppPrefsCocoa.shared.setTextEditingFont(object: textView)
        
        // Add the Text View to the Scroll View
        scrollView.documentView = textView

    }
    
}

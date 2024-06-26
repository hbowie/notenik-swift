//
//  PageStyleView.swift
//  Notenik
//
//  Created by Herb Bowie on 4/23/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

public class PageStyleView: MacEditView {
    
    var scrollView: NSScrollView!
    var textView:   NSTextView!
    
    var view: NSView {
        return scrollView
    }
    
    public var text: String {
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
        textView.isAutomaticQuoteSubstitutionEnabled = false
        
        AppPrefsCocoa.shared.setCodeEditingFont(view: textView)
        
        // Add the Text View to the Scroll View
        scrollView.documentView = textView
        
    }
        
}

//
//  NoteScroller.swift
//  Notenik
//
//  Created by Herb Bowie on 7/3/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class NoteScroller {
    
    var collection: NoteCollection
    
    var lastPositionFrom: LastPositionFrom = .nowhere
    
    //
    // Values from the Display tab.
    //
    
    // The estimated height of the display header.
    var displayHeaderHeight = 30
    
    // The scroll position.
    var displayOffset: Int = 0
    
    // The total height of the content.
    var displayHeight: Int = 0
    
    // The height of the visible content.
    var displayVis:    Int = 0
    
    //
    // Values from the Edit tab.
    //
    
    // The scroll position.
    var editOffset:    Int = 0
    
    // The total height of the content.
    var editHeight:    Int = 0
    
    // The height of the visible content.
    var editVis:       Int = 0
    
    var fudgeFactor1: Double = 0.85
    var fudgeFactor2: Double = 0.08
    
    var editScrollView: NSScrollView?
    
    var displayDataReturned = 0
    
    
    init(collection: NoteCollection) {
        print("NoteScroller.init")
        self.collection = collection
    }
    
    func editStart(scrollView: NSScrollView) {
        print("NoteScroller.editStart")
        editScrollView = scrollView
        editHeight = 0
        if let contentSize = scrollView.documentView?.bounds.height {
            editHeight = Int(contentSize)
        }
    }
    
    func editEnd(scrollView: NSScrollView) {
        print("NoteScroller.editEnd")
        if let contentSize = scrollView.documentView?.bounds.height {
            editHeight = Int(contentSize)
        }
        let docVis = scrollView.documentVisibleRect
        editOffset = Int(docVis.origin.y)
        editVis = Int(docVis.height)
        lastPositionFrom = .edit
    }
    
    func displayStart(note: Note, webView: NoteDisplayWebView) {
        
        print("NoteScroller.displayStart")
        guard collection.scrollingSync else { return }
        var scrollY = 0
        
        switch lastPositionFrom {
        case .display:
            scrollY = displayOffset
        case .edit:
            print("  - edit offset = \(editOffset)")
            print("  - edit height = \(editHeight)")
            print("  - edit vis    = \(editVis)")
            if editOffset == 0 {
                scrollY = 0
            } else {
                let percent: Double = Double(editOffset) / Double((editHeight - editVis))
                let ff2Factor = fudgeFactor2 - percent
                let ff2Applied = fudgeFactor2 * ff2Factor
                let fudgeFactor = fudgeFactor1 + ff2Applied
                let fudged = percent * fudgeFactor
                print("  - edit percent scrolled = \(percent)")
                print("  - fudge factor 1 = \(fudgeFactor1)")
                print("  - fudge factor 2 = \(fudgeFactor2)")
                print("  - fudge factor 2 applied = \(ff2Applied)")
                print("  - fudge factor = \(fudgeFactor)")
                print("  - fudged percent = \(fudged)")
                print("  - display height   = \(displayHeight)")
                print("  - display header height = \(displayHeaderHeight)")
                print("  - display vis = \(displayVis)")
                let equiv: Double = Double(displayHeaderHeight)
                    + Double(displayHeight - displayHeaderHeight) * fudged
                print("  - equivalent scroll = \(equiv)")
                scrollY = Int(equiv.rounded(.toNearestOrAwayFromZero))
                print("  - scroll Y = \(scrollY)")
            }
        case .nowhere:
            break
        }
        
        guard scrollY > 0 else { return }
        
        let js = "window.scroll(0, \(scrollY));"
        // print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
    }
    
    func displayEnd(note: Note, webView: NoteDisplayWebView) {
        print("NoteScroller.displayEnd")
        guard collection.scrollingSync else {
            if editOffset > 0 {
                if let scrollView = editScrollView {
                    let newOrigin = NSPoint(x: 0, y: editOffset)
                    scrollView.contentView.scroll(to: newOrigin)
                }
            }
            return
        }
        displayOffset = 0
        displayDataReturned = 0
        
        // Get the current scroll position
        var js = "window.pageYOffset;"
        // print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if let resultNumber = result as? NSNumber {
                self.displayOffset = resultNumber.intValue
                self.displayDataReturned += 1
                if self.displayDataReturned >= 3 {
                    self.editScrollUsingDisplayData()
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        // Get the total scrollable height
        js = "window.document.body.scrollHeight;"
        // print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if let resultNumber = result as? NSNumber {
                self.displayHeight = resultNumber.intValue
                self.displayDataReturned += 1
                if self.displayDataReturned >= 3 {
                    self.editScrollUsingDisplayData()
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        // Get the height of the visible window.
        js = "window.document.documentElement.clientHeight;"
        // print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if let resultNumber = result as? NSNumber {
                self.displayVis = resultNumber.intValue
                self.displayDataReturned += 1
                if self.displayDataReturned >= 3 {
                    self.editScrollUsingDisplayData()
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        lastPositionFrom = .display
    }
    
    func editScrollUsingDisplayData() {
        print("  - NoteScroller.editScrollUsingDisplayData")
        guard let scrollView = editScrollView else {
            print("  - no edit scroll view available!")
            return
        }
        if let contentSize = scrollView.documentView?.bounds.height {
            editHeight = Int(contentSize)
        }
        print("  - display offset = \(displayOffset)")
        var scrollY = 0
        if displayOffset == 0 {
            scrollY = 0
        } else {
            print("  - display height = \(displayHeight)")
            print("  - display vis    = \(displayVis)")
            let percent: Double = Double(displayOffset) / Double((displayHeight - displayVis))
            print("  - percent scrolled = \(percent)")
            let equiv: Double = Double(editHeight) * percent
            print("  - edit height = \(editHeight)")
            scrollY = Int(equiv.rounded(.toNearestOrAwayFromZero))
        }
        print("  - scroll Y = \(scrollY)")
        let newOrigin = NSPoint(x: 0, y: scrollY)
        scrollView.contentView.scroll(to: newOrigin)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "NoteDisplayViewController",
                          level: .error,
                          message: msg)
    }
    
    func display() {
        print("  + NoteScroller.display")
        print("    - last position from: \(lastPositionFrom)")
        print("    - display offset: \(displayOffset)")
        print("    - display height: \(displayHeight)")
        print("    - visible height: \(displayVis)")
        print("    - edit offset: \(editOffset)")
        print("    - edit height: \(editHeight)")
        print("    - edit visible height: \(editVis)")
    }
    
    enum LastPositionFrom {
        case display
        case edit
        case nowhere
    }
    
}

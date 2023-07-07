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
    var lastNoteTitle = ""
    
    //
    // Values from the Display tab.
    //
    
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
    
    var editScrollPending = false
    
    var editScrollView: NSScrollView?
    
    var displayDataPending = false
    
    var displayDataReturned = 0
    
    
    init(collection: NoteCollection) {
        self.collection = collection
    }
    
    func saveDisplayPosition(note: Note, webView: NoteDisplayWebView) {
        print("NoteScroller.saveDisplayPosition")
        displayOffset = 0
        lastNoteTitle = note.title.value
        print("  - scroll title = '\(lastNoteTitle)'")
        
        displayDataPending = true
        displayDataReturned = 0
        
        // Get the current scroll position
        var js = "window.pageYOffset;"
        print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if result != nil {
                if let resultNumber = result as? NSNumber {
                    print("    - numeric result = \(resultNumber)")
                    self.displayOffset = resultNumber.intValue
                    self.displayDataReturned += 1
                    if self.displayDataReturned >= 3 && self.editScrollPending {
                        self.editScrolUsingDisplayData()
                    }
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        // Get the total scrollable height
        js = "window.document.body.scrollHeight;"
        print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if result != nil {
                if let resultNumber = result as? NSNumber {
                    print("    - numeric result = \(resultNumber)")
                    self.displayHeight = resultNumber.intValue
                    self.displayDataReturned += 1
                    if self.displayDataReturned >= 3 && self.editScrollPending {
                        self.editScrolUsingDisplayData()
                    }
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        // Get the height of the visible window.
        js = "window.document.documentElement.clientHeight;"
        print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if result != nil {
                if let resultNumber = result as? NSNumber {
                    print("    - numeric result = \(resultNumber)")
                    self.displayVis = resultNumber.intValue
                    self.displayDataReturned += 1
                    if self.displayDataReturned >= 3 && self.editScrollPending {
                        self.editScrolUsingDisplayData()
                    }
                }
            }
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
        
        lastPositionFrom = .display
        
        display()
    }
    
    func setDisplayPosition(note: Note, webView: NoteDisplayWebView) {
        
        print("NoteScroller.setDisplayPosition for note title of \(note.title.value)")
        display()
        
        guard note.title.value == lastNoteTitle else {
            lastNoteTitle = ""
            return
        }

        var scrollY = 0
        
        switch lastPositionFrom {
        case .display:
            scrollY = displayOffset
        case .edit:
            if editOffset == 0 {
                scrollY = 0
            } else {
                let percent: Double = Double(editOffset) / Double((editHeight - editVis))
                print("  - percent scrolled = \(percent)")
                let equiv: Double = Double(displayHeight) * percent
                scrollY = Int(equiv.rounded(.toNearestOrAwayFromZero))
            }
        case .nowhere:
            return
        }
        
        guard scrollY > 0 else { return }
        
        let js = "window.scroll(0, \(scrollY));"
        print("  - evaluate javascript: \(js)")
        webView.evaluateJavaScript(js) { (result, error) in
            if error != nil {
                self.communicateError("    - Error returned: \(error!)")
            }
        }
    
    }
    
    func saveEditPosition(note: Note, scrollView: NSScrollView) {
        print("NoteScroller.saveEditPosition")
        
        if let contentSize = scrollView.documentView?.bounds.height {
            editHeight = Int(contentSize)
        }
        
        let docVis = scrollView.documentVisibleRect
        editOffset = Int(docVis.origin.y)
        editVis = Int(docVis.height)
        
        /* if let docBounds = scrollView.documentView?.bounds {
            editVis = docBounds.size.height
            print("  - doc bounds = \(docBounds)")
        } */
        lastPositionFrom = .edit
        display()
    }
    
    func setEditPosition(note: Note, scrollView: NSScrollView) {
        print("NoteScroller.setEditPosition for note title of \(note.title.value)")
        display()
        
        editScrollPending = false
        
        guard note.title.value == lastNoteTitle else {
            lastNoteTitle = ""
            return
        }

        editScrollView = scrollView
        var scrollY = 0
        
        switch lastPositionFrom {
        case .display:
            if displayDataPending {
                editScrollPending = true
            } else {
                editScrolUsingDisplayData()
            }
            return
        case .edit:
            scrollY = editOffset
        case .nowhere:
            return
        }
        
        guard scrollY > 0 else { return }
        
        let newOrigin = NSPoint(x: 0, y: scrollY)
        scrollView.contentView.scroll(to: newOrigin)
    }
    
    func editScrolUsingDisplayData() {
        guard let scrollView = editScrollView else { return }
        guard editScrollPending else { return }
        editScrollPending = false
        var scrollY = 0
        if displayOffset == 0 {
            scrollY = 0
        } else {
            let percent: Double = Double(displayOffset) / Double((displayHeight - displayVis))
            print("  - percent scrolled = \(percent)")
            let equiv: Double = Double(editHeight) * percent
            scrollY = Int(equiv.rounded(.toNearestOrAwayFromZero))
        }
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
        print("    - last note title: \(lastNoteTitle)")
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

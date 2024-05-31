//
//  NoteSplitViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/10/19.
//  Copyright © 2019-2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class NoteSplitViewController: NSSplitViewController {
    
    var previousDividerPosition: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.autosaveName = "save-me"
        if leftViewCollapsed {
            _ = changeLeftViewVisibility(makeVisible: true)
        }
    }
    
    /// Let's make sure that a subview can be collapsed.
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return splitView.subviews[0] == subview
    }
    
    /// The actual mechanics of showing or hiding the leftmost view.
    func changeLeftViewVisibility(makeVisible: Bool) -> CGFloat {
        var newPosition: CGFloat = 0.0
        if makeVisible {
            if previousDividerPosition > 0.0 {
                newPosition = previousDividerPosition
            } else {
                newPosition = 500.0
            }
        } else {
            previousDividerPosition = leftViewWidth
            newPosition = 0.0
        }
        splitView.setPosition(newPosition, ofDividerAt: 0)
        splitView.layoutSubtreeIfNeeded()
        return newPosition
    }
    
    /// Get the leftmost view.
    var leftView: NSView {
        return splitView.subviews[0]
    }
    
    /// Is the left view collapsed?
    var leftViewCollapsed: Bool {
        return splitView.isSubviewCollapsed(leftView)
    }
    
    /// Get the width of the leftmost view.
    var leftViewWidth: CGFloat {
        if leftViewCollapsed {
            return 0.0
        } else {
            return leftView.frame.size.width
        }
    }
    
}

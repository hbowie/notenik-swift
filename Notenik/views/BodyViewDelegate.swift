//
//  BodyViewDelegate.swift
//  Notenik
//
//  Created by Herb Bowie on 12/22/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

public class BodyViewDelegate: NSObject, NSTextViewDelegate {
    
    var conMenu: NSMenu?
    var lookupItem: NSMenuItem?

    public func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        conMenu = menu
        // conMenu!.addItem(NSMenuItem.separator())
        lookupItem = NSMenuItem(title: "Complete wiki link...", action: #selector(lookupPartialWikiLinks(_:)), keyEquivalent: "")
        lookupItem?.target = self
        lookupItem?.isEnabled = true
        // conMenu!.addItem(lookupItem!)
        return conMenu
    }
    
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    @IBAction public func lookupPartialWikiLinks(_ sender: AnyObject) {
        print("Lookup Partial Wiki Links invoked!")
    }

}

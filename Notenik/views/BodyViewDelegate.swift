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
    
    public func textShouldBeginEditing(_ textObject: NSText) -> Bool {
        print("Body View Should begin editing")
        return true
    }
    
    public func textDidBeginEditing(_ notification: Notification) {
        print("Body View Did begin editing")
    }
    
    public func textShouldEndEditing(_ textObject: NSText) -> Bool {
        print("Body View Should end editing")
        return true
    }
    
    public func textDidEndEditing(_ notification: Notification) {
        print("Body View Did end editing")
        if let userInfo = notification.userInfo {
            if let textMovement = userInfo["NSTextMovement"] {
                print("  - text movement: \(textMovement)")
            }
        }
    }

}

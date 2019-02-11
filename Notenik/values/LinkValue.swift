//
//  LinkValue.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

class LinkValue : StringValue {
    
    /**
     Part 1 of the url, delimited by a colon and zero or more slashes
     (as in "http://" or "mailto:")
     */
    var linkPart1 : Substring? = nil
    
    /// The user name part of an e-mail address, if one is present, or the sub-domain.
    var linkPart2 : Substring? = nil
    
    /// The domain name
    var linkPart3 : Substring? = nil
    
    /// Anything following the domain name, except for a trailing slash.
    var linkPart4 : Substring? = nil
    
    /// An ending slash, if one is present. */
    var linkPart5 : Substring? = nil
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Convenience init with an actual URL object
    convenience init (_ url : URL) {
        self.init()
        set(url)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    override var sortKey: String {
        return getLinkPart3() + getLinkPart1() + getLinkPart2() + getLinkPart4()
    }
    
    /// Return the first part of the link (up to the initial colon) as a string
    func getLinkPart1() -> String {
        if linkPart1 == nil {
            return ""
        } else {
            return String(linkPart1!)
        }
    }
    
    /// Return the second part of the link (up to the at sign or initial period) as a string
    func getLinkPart2() -> String {
        if linkPart2 == nil {
            return ""
        } else {
            return String(linkPart2!)
        }
    }
    
    /// Return the third part of the link (the domain name) as a string
    func getLinkPart3() -> String {
        if linkPart3 == nil {
            return ""
        } else {
            return String(linkPart3!)
        }
    }
    
    /// Return the fourth part of the link (following the domain name) as a string
    func getLinkPart4() -> String {
        if linkPart4 == nil {
            return ""
        } else {
            return String(linkPart4!)
        }
    }
    
    /// Return the final part of the link (an optional trailing slash) as a string
    func getLinkPart5() -> String {
        if linkPart5 == nil {
            return ""
        } else {
            return String(linkPart5!)
        }
    }
    
    /// Return the link value as an optional URL
    func getURL() -> URL? {
        let url = URL(string: value)
        return url
    }
    
    /// Set the link value from an actual URL
    func set(_ url : URL) {
        let path = url.absoluteString
        set(path)
    }
    
    /// Parse the input string and break it down into its various components
    override func set(_ value: String) {
        
        super.set(value)
        
        linkPart1 = nil
        linkPart2 = nil
        linkPart3 = nil
        linkPart4 = nil
        linkPart5 = nil
        
        var p1End = -1
        var p2End = -1
        var p3End = -1
        var p4End = -1
        var p5End = -1
        
        var firstPeriod = -1
        var periodCount = 0
        
        var i = 0
        let last = self.value.count - 1
        
        for c in self.value {
            if c == ":" && p1End < 0  {
                p1End = i
            } else if c == "/" && i == (p1End + 1) {
                p1End = i
            } else if c == "@" && p2End < 0 {
                p2End = i
            } else if c == "." && p3End < 0 {
                if periodCount == 0 {
                    firstPeriod = i
                }
                periodCount += 1
            } else if (c == "/"  || i == last) && p3End < 0 {
                p3End = i
                if periodCount > 1 && p2End < 0 {
                    p2End = firstPeriod
                }
                if p2End < 0 {
                    p2End = p1End
                }
            } else if c == "/" && i == last {
                p4End = i - 1
                p5End = i
            } else if i == last {
                p4End = i
            }
            i += 1
        }
        
        let p1StartIndex = self.value.startIndex
        var p2StartIndex = self.value.startIndex
        var p3StartIndex = self.value.startIndex
        var p4StartIndex = self.value.startIndex
        var p5StartIndex = self.value.startIndex
        
        if p1End >= 0 {
            let p1EndIndex = self.value.index(p1StartIndex, offsetBy: p1End)
            linkPart1 = self.value [self.value.startIndex...p1EndIndex]
            p2StartIndex = self.value.index(self.value.startIndex, offsetBy: p1End + 1)
            p3StartIndex = p2StartIndex
            p4StartIndex = p2StartIndex
            p5StartIndex = p2StartIndex
        }
        
        if p2End >= 0 && p2End > p1End {
            let p2EndIndex = self.value.index(self.value.startIndex, offsetBy: p2End)
            linkPart2 = self.value [p2StartIndex...p2EndIndex]
            p3StartIndex = self.value.index(self.value.startIndex, offsetBy: p2End + 1)
            p4StartIndex = p3StartIndex
            p5StartIndex = p3StartIndex
        }
        
        if p3End >= 0 && p3End > p2End {
            let p3EndIndex = self.value.index(self.value.startIndex, offsetBy: p3End)
            linkPart3 = self.value [p3StartIndex...p3EndIndex]
            p4StartIndex = self.value.index(self.value.startIndex, offsetBy: p3End + 1)
            p5StartIndex = p4StartIndex
        }
        
        if p4End >= 0 && p4End > p3End {
            let p4EndIndex = self.value.index(self.value.startIndex, offsetBy: p4End)
            linkPart4 = self.value [p4StartIndex...p4EndIndex]
            p5StartIndex = self.value.index(self.value.startIndex, offsetBy: p4End + 1)
        }
        
        if p5End >= 0 && p5End > p4End && p5End > p3End {
            let p5EndIndex = self.value.index(self.value.startIndex, offsetBy: p5End)
            linkPart5 = self.value [p5StartIndex...p5EndIndex]
        }
    }
}

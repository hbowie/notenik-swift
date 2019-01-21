//
//  TagsValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/4/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// One or more tags, each consisting of one or more levels
class TagsValue : StringValue {
    
    var tags : [TagValue] = []
    
    /// Default initializer
    override init() {
        super.init()
    }
    
    /// Convenience initializer with String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    
    /// Set a new value for the tags.
    ///
    /// - Parameter value: The new value for the tags, with commas or semi-colons separating tags,
    ///                    and periods or slashes separating levels within a tag.
    override func set(_ value: String) {
        
        super.set(value)
        
        var tag = TagValue()
        var level = ""
        
        /// Loop through new value
        for c in value {
            if c == "," || c == ";" || c == "." || c == "/" {
                if level.count > 0 {
                    tag.addLevel(level)
                    level = ""
                }
                if (c == "," || c == ";") && tag.count > 0 {
                    tags.append(tag)
                    tag = TagValue()
                }
            } else if c == " " {
                if level.count > 0 {
                  level.append(c)
                }
            } else if StringUtils.isAlpha(c) || StringUtils.isDigit(c) || c == "-" || c == "_" {
                level.append(c)
            }
        }
        
        /// Finish up
        if level.count > 0 {
            tag.addLevel(level)
        }
        if tag.count > 0 {
            tags.append(tag)
        }
    }
    
    /// Sort the tags alphabetically
    func sort() {
        tags.sort { $0.description < $1.description }
        value = ""
        var x = 0
        for tag in tags {
            if x > 0 {
                value.append(", ")
            }
            var y = 0
            for level in tag.levels {
                if y > 0 {
                    value.append(".")
                }
                value.append(level)
                y += 1
            }
            x += 1
        }
    }
    
    func getTag(_ x : Int) -> String? {
        if x < 0 || x >= tags.count {
            return nil
        } else {
            return tags[x].description
        }
    }
    
    func getLevel(tagIndex : Int, levelIndex : Int) -> String? {
        if tagIndex < 0 || tagIndex >= tags.count {
            return nil
        } else {
            let tag = tags[tagIndex]
            if levelIndex < 0 || levelIndex >= tag.count {
                return nil
            } else {
                return tag.levels[levelIndex]
            }
        }
    }
    
    class TagValue: CustomStringConvertible, Equatable, Comparable {
        
        var levels : [String] = []
        
        var description: String {
            var str = ""
            for level in levels {
                if str.count > 0 {
                    str.append(".")
                }
                str.append(level)
            }
            return str
        }
        
        var count: Int {
            return levels.count
        }
        
        func addLevel(_ level : String) {
            levels.append(level)
        }
        
        static func == (lhs: TagsValue.TagValue, rhs: TagsValue.TagValue) -> Bool {
            return lhs.description == rhs.description
        }
        
        static func < (lhs: TagsValue.TagValue, rhs: TagsValue.TagValue) -> Bool {
            return lhs.description < rhs.description
        }
        
    }
}

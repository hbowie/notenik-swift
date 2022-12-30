//
//  NoteToPick.swift
//  Notenik
//
//  Created by Herb Bowie on 12/28/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import NotenikLib
import NotenikUtils

class NoteToPick: CustomStringConvertible, Comparable {

    var title: StringVar!
    var tags: TagsValue!
    var tagsLower = ""
    var matchingTag = ""
    
    var description: String {
        return title.original
    }
    
    init(title: String, tags: TagsValue) {
        self.title = StringVar(title)
        self.tags = tags
        tagsLower = tags.value.lowercased()
    }
    
    func setMatchingTag(tagToMatch: StringVar) {
        matchingTag = ""
        guard !tagToMatch.isEmpty else { return }
        for tag in tags.tags {
            if tag.value.lowercased().contains(tagToMatch.lowered) {
                matchingTag = tag.value
                return
            }
        }
    }
    
    func getMarkdown(includeTag: Bool) -> String {
        if includeTag && !matchingTag.isEmpty {
            return "#*\(matchingTag)* | \(title.original)"
        } else {
            return title.original
        }
    }
    
    static func == (lhs: NoteToPick, rhs: NoteToPick) -> Bool {
        return (lhs.title == rhs.title)
    }
    
    static func < (lhs: NoteToPick, rhs: NoteToPick) -> Bool {
        return lhs.title < rhs.title
    }
}

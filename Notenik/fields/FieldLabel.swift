//
//  FieldLabel.swift
//  Notenik
//
//  Created by Herb Bowie on 11/30/18.
//  Copyright © 2018 - 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A label used to identify a particular field within a collection of items.
class FieldLabel: CustomStringConvertible {
    
    var properForm = ""
    var commonForm = ""
    var validLabel = false
    
    init() {
    
    }
    
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    func set(_ label: String) {
        properForm = label
        commonForm = StringUtils.toCommon(label)
        if isAuthor && commonForm != LabelConstants.authorCommon {
            properForm = LabelConstants.author
            commonForm = LabelConstants.authorCommon
        } else if isLink && commonForm != LabelConstants.linkCommon {
            properForm = LabelConstants.link
            commonForm = LabelConstants.linkCommon
        } else if isRating && commonForm != LabelConstants.ratingCommon {
            properForm = LabelConstants.rating
            commonForm = LabelConstants.ratingCommon
        } else if isRecurs && commonForm != LabelConstants.recursCommon {
            properForm = LabelConstants.recurs
            commonForm = LabelConstants.recursCommon
        } else if isSeq && commonForm != LabelConstants.seqCommon {
            properForm = LabelConstants.seq
            commonForm = LabelConstants.seqCommon
        } else if isTags && commonForm != LabelConstants.tagsCommon {
            properForm = LabelConstants.tags
            commonForm = LabelConstants.tagsCommon
        }
    }
    
    var isAuthor: Bool {
        return (commonForm == LabelConstants.authorCommon
            || commonForm == "by"
            || commonForm == "creator")
    }
    
    var isBody: Bool {
        return commonForm == LabelConstants.bodyCommon
    }
    
    var isCode: Bool {
        return commonForm == LabelConstants.codeCommon
    }
    
    var isDate: Bool {
        return commonForm == LabelConstants.dateCommon
    }
    
    var isDateAdded: Bool {
        return commonForm == LabelConstants.dateAddedCommon
    }
    
    var isIndex: Bool {
        return commonForm == LabelConstants.indexCommon
    }
    
    var isLink: Bool {
        return (commonForm == LabelConstants.linkCommon
            || commonForm == "url")
    }
    
    var isRating: Bool {
        return (commonForm == LabelConstants.ratingCommon
            || commonForm == "priority")
    }
    
    var isRecurs: Bool {
        return (commonForm == LabelConstants.recursCommon
            || commonForm == "every"
            || (commonForm.hasPrefix(LabelConstants.recursCommon)
                && commonForm.hasSuffix("every")))
    }
    
    var isSeq: Bool {
        return (commonForm == LabelConstants.seqCommon
            || commonForm == "sequence"
            || commonForm == "rev"
            || commonForm == "revision"
            || commonForm == "version")
    }
    
    var isStatus: Bool {
        return (commonForm == LabelConstants.statusCommon)
    }
    
    var isTags: Bool {
        return (commonForm == LabelConstants.tagsCommon
            || commonForm == "keywords"
            || commonForm == "category"
            || commonForm == "categories")
    }
    
    var isTeaser: Bool {
        return (commonForm == LabelConstants.teaserCommon)
    }
    
    var isTimestamp: Bool {
        return (commonForm == LabelConstants.timestampCommon)
    }
    
    var isTitle: Bool {
        return commonForm == LabelConstants.titleCommon
        
    }
    
    var isType: Bool {
        return commonForm == LabelConstants.typeCommon
    }
    
    var isWorkTitle: Bool {
        return commonForm == LabelConstants.workTitleCommon
    }
    
    var isWorkType: Bool {
        return commonForm == LabelConstants.workTypeCommon
    }
    
    var count: Int {
        return properForm.count
    }
    
    var description: String {
        return properForm
    }
    
    var isEmpty: Bool {
        return (properForm.count == 0)
    }
    
    var hasData: Bool {
        return (properForm.count > 0)
    }
    
    func display() {
        print("FieldLabel | Proper Form: \(properForm), Common Form: \(commonForm), Valid? \(validLabel)")
    }
}
